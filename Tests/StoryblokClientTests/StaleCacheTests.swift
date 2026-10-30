import Combine
import Foundation
import Testing
@testable import StoryblokClient

@BlockLibrary
enum CacheBlock: Decodable {
    case page(Page)

    struct Page: Decodable {
        let title: String
        let related: [String]
    }
}

/// A cached copy saved before the content changed shape, here before the page block gained its required `related`
/// field, gives way to the copy the request loads instead of failing the publisher before that copy arrives.
///
/// Served by a stub protocol only this suite's sessions use, as `CachedDataTaskPublisherTests` is, with cached
/// responses in each client's own URL cache.
@Suite(.serialized)
struct StaleCacheTests {

    /// Answers a cache-only request with the cached response URLSession hands it, and every other request with
    /// `loaded`, recording the URL it was asked for.
    final class Stub: URLProtocol {

        nonisolated(unsafe) static var loaded = ""
        nonisolated(unsafe) static var requested: [URL] = []
        static let lock = NSLock()

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func stopLoading() {}

        override func startLoading() {
            if request.cachePolicy == .returnCacheDataDontLoad, let cachedResponse {
                client?.urlProtocol(self, cachedResponseIsValid: cachedResponse)
                return
            }
            let body = Self.lock.withLock {
                Self.requested.append(request.url!)
                return Self.loaded
            }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    private let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    private let client: StoryblokClient<CacheBlock>

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Stub.self]
        configuration.urlCache = cache
        client = StoryblokClient(library: CacheBlock.self, accessToken: "mock-api-key", configuration: configuration)
    }

    private static let before = #"{"_uid": "c", "component": "page", "title": "Before"}"#
    private static let after = #"{"_uid": "c", "component": "page", "title": "After", "related": []}"#

    private func story(_ content: String) -> String {
        """
        {"id": 1, "uuid": "11111111-1111-1111-1111-111111111111", "name": "Home", "content": \(content),
         "slug": "home", "full_slug": "home", "created_at": "2025-07-09T14:35:26.851Z", "published_at": null,
         "first_published_at": null, "updated_at": null, "sort_by_date": null, "position": 0, "tag_list": [],
         "is_startpage": false, "parent_id": null, "meta_data": null, "group_id": "33333333-3333-3333-3333-333333333333",
         "release_id": null, "lang": "default", "path": null, "alternates": [], "default_full_slug": null,
         "translated_slugs": null}
        """
    }

    /// Collects what `publisher` sends when the cache holds `cached` and the request loads `loaded`, along with the
    /// failure that ended it, if any. The URL to cache under is the one the publisher requests, found by running it
    /// once first with the cache empty.
    private func collect<Output>(
        cached: String,
        loaded: String,
        _ publisher: () -> AnyPublisher<Output, StoryblokClient<CacheBlock>.Error>
    ) async -> (values: [Output], failure: (any Error)?) {
        Stub.lock.withLock {
            Stub.loaded = loaded
            Stub.requested = []
        }
        cache.removeAllCachedResponses()
        _ = try? await publisher().values.first { _ in true }
        let url = Stub.lock.withLock { Stub.requested.last! }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        cache.storeCachedResponse(CachedURLResponse(response: response, data: Data(cached.utf8)), for: URLRequest(url: url))

        var values: [Output] = []
        do {
            for try await value in publisher().values { values.append(value) }
            return (values, nil)
        } catch {
            return (values, error)
        }
    }

    private func home() -> AnyPublisher<Story<CacheBlock>, StoryblokClient<CacheBlock>.Error> {
        client.story("home")
    }

    private func pages() -> AnyPublisher<Page<Story<CacheBlock.Page>>, StoryblokClient<CacheBlock>.Error> {
        client.stories()
    }

    private func titles(_ stories: [Story<CacheBlock>]) -> [String] {
        stories.map { story in
            guard case .page(let page) = story.content else { return "" }
            return page.title
        }
    }

    @Test
    func `a cached story that no longer decodes gives way to the loaded one`() async {
        let result = await collect(cached: #"{"story": \#(story(Self.before))}"#, loaded: #"{"story": \#(story(Self.after))}"#, home)

        #expect(result.failure == nil)
        #expect(titles(result.values) == ["After"])
    }

    @Test
    func `a cached story that decodes is still published before the loaded one`() async {
        let cached = story(#"{"_uid": "c", "component": "page", "title": "Cached", "related": []}"#)
        let result = await collect(cached: #"{"story": \#(cached)}"#, loaded: #"{"story": \#(story(Self.after))}"#, home)

        #expect(result.failure == nil)
        #expect(titles(result.values) == ["Cached", "After"])
    }

    @Test
    func `a loaded story that does not decode still fails the publisher`() async {
        let result = await collect(cached: #"{"story": \#(story(Self.before))}"#, loaded: #"{"story": \#(story(Self.before))}"#, home)

        #expect(result.values.isEmpty)
        guard case .decoding? = result.failure as? StoryblokClient<CacheBlock>.Error else {
            Issue.record("expected a decoding failure, got \(String(describing: result.failure))")
            return
        }
    }

    @Test
    func `a cached page of stories that no longer decodes gives way to the loaded one`() async {
        let result = await collect(cached: #"{"stories": [\#(story(Self.before))]}"#, loaded: #"{"stories": [\#(story(Self.after))]}"#, pages)

        #expect(result.failure == nil)
        #expect(result.values.map { $0.map(\.content.title) } == [["After"]])
    }
}
