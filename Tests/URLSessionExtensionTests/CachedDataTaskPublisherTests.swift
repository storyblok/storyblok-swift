import Testing
import Foundation
import Combine
@testable import URLSessionExtension

/// Served by a stub protocol only this suite's session uses, rather than Mocker, whose shared
/// registrations other suites clear while they run alongside this one. Cached responses go in the
/// session's own URL cache: URLSession fails a cache-only request itself when the cache holds
/// nothing, and otherwise hands the protocol the cached response to answer it with.
@Suite(.serialized)
struct CachedDataTaskPublisherTests {

    /// Answers a cache-only request with the cached response URLSession hands it, and every other
    /// request with the next of `loaded`, repeating the last once they run out.
    final class Stub : URLProtocol {

        nonisolated(unsafe) static var loaded: [(status: Int, body: String)] = []
        nonisolated(unsafe) static var attempts = 0
        static let lock = NSLock()

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func stopLoading() {}

        override func startLoading() {
            if request.cachePolicy == .returnCacheDataDontLoad, let cachedResponse {
                client?.urlProtocol(self, cachedResponseIsValid: cachedResponse)
                return
            }
            let answer = Self.lock.withLock {
                Self.attempts += 1
                return Self.loaded[min(Self.attempts, Self.loaded.count) - 1]
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: answer.status, httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(answer.body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    let url = URL(string: "https://example.com/stories")!
    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Stub.self]
        configuration.urlCache = cache
        session = URLSession(configuration: configuration)
    }

    /// Publishes for a request with `cached` in the cache and `loaded` as the responses to it,
    /// returning the bodies published, the failure that ended it, if any, and how many times the
    /// request was attempted.
    private func publish(
        cached: String?,
        loaded: [(status: Int, body: String)]
    ) async -> (bodies: [String], failure: (any Error)?, attempts: Int) {
        Stub.lock.withLock {
            Stub.loaded = loaded
            Stub.attempts = 0
        }
        cache.removeAllCachedResponses()
        if let cached {
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            cache.storeCachedResponse(CachedURLResponse(response: response, data: Data(cached.utf8)), for: URLRequest(url: url))
        }

        var bodies: [String] = []
        var failure: (any Error)?
        do {
            for try await output in session.cachedDataTaskPublisher(for: url).values {
                bodies.append(String(decoding: output.data, as: UTF8.self))
            }
        } catch {
            failure = error
        }
        return (bodies, failure, Stub.lock.withLock { Stub.attempts })
    }

    @Test
    func `with nothing cached, publishes the loaded response`() async {
        let result = await publish(cached: nil, loaded: [(200, "fresh")])

        #expect(result.bodies == ["fresh"])
        #expect(result.failure == nil)
        #expect(result.attempts == 1)
    }

    @Test
    func `publishes the cached response, then the loaded one`() async {
        let result = await publish(cached: "cached", loaded: [(200, "fresh")])

        #expect(result.bodies == ["cached", "fresh"])
        #expect(result.failure == nil)
    }

    @Test
    func `a loaded response matching the cached one is not published again`() async {
        let result = await publish(cached: "same", loaded: [(200, "same")])

        #expect(result.bodies == ["same"])
    }

    @Test
    func `a recoverable error response is retried`() async {
        let result = await publish(cached: nil, loaded: [(500, "busy"), (200, "fresh")])

        #expect(result.bodies == ["fresh"])
        #expect(result.attempts == 2)
    }

    @Test
    func `an error response that persists fails after three retries, after the cached response`() async {
        let result = await publish(cached: "cached", loaded: [(500, "down")])

        #expect(result.bodies == ["cached"], "the cached response is still delivered")
        #expect(result.attempts == 4, "the first attempt and three retries")
        guard case .server(statusCode: 500, _, _) = result.failure as? Api.ResponseError else {
            Issue.record("expected a server ResponseError, got \(String(describing: result.failure))")
            return
        }
    }

    @Test
    func `a client error response is not retried`() async {
        let result = await publish(cached: nil, loaded: [(404, "missing")])

        #expect(result.bodies.isEmpty)
        #expect(result.attempts == 1)
        guard case .client(statusCode: 404, _, _) = result.failure as? Api.ResponseError else {
            Issue.record("expected a client ResponseError, got \(String(describing: result.failure))")
            return
        }
    }
}
