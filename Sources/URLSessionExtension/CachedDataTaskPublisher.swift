import Foundation
import Combine

extension URLSession {

    /// A publisher that delivers the response the URL cache holds for a request, then the response
    /// the request loads.
    ///
    /// Create one with ``Foundation/URLSession/cachedDataTaskPublisher(for:)-(URLRequest)``. It is
    /// the stale-while-revalidate counterpart of
    /// [`DataTaskPublisher`](https://developer.apple.com/documentation/foundation/urlsession/datataskpublisher):
    /// a view can show what it last received at once, then update when the request completes.
    ///
    /// - The cached response is read without touching the network. When the cache holds none, or
    ///   holds an error response, the publisher skips straight to the request: only a successful
    ///   response stands in for the one the request loads.
    /// - The request is then performed with its own cache policy. Transient failures — network
    ///   errors and the error responses ``Api/ErrorResponseType/recoverable`` covers — are retried
    ///   up to three times, and any error response then fails the publisher with a
    ///   ``Api/ResponseError``, as described in <doc:UserGuide#Retrying-failed-requests>.
    /// - When the request's response has the same data and `total` header as the cached one, it is
    ///   not published again. A paginated endpoint reports its element count in `total`, so a page
    ///   whose count changed is published even when its elements did not.
    ///
    /// A failure of the request ends the publisher after the cached response, if there was one, so a
    /// subscriber that keeps the last value received still has it.
    public struct CachedDataTaskPublisher : Publisher {

        public typealias Output = (data: Data, response: URLResponse)
        public typealias Failure = any Error

        /// The request the publisher performs, after reading its cached response.
        public let request: URLRequest

        /// The session that performs the request.
        public let session: URLSession

        /// Creates a publisher that delivers the cached response for `request`, then the response
        /// `session` loads for it.
        public init(request: URLRequest, session: URLSession) {
            self.request = request
            self.session = session
        }

        public func receive<S : Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            var cachedRequest = request
            cachedRequest.cachePolicy = .returnCacheDataDontLoad

            // A cache miss fails the cached request, which here means there is nothing to publish yet.
            // A cached error response is passed over as well, rather than published as content.
            let cached = session.dataTaskPublisher(for: cachedRequest)
                .filter { isSuccess($0.response) }
                .map { (data: $0.data, response: $0.response) }
                .catch { _ in Empty<Output, URLError>() }
                .mapError { $0 as any Error }

            // Retried on its own: a retry around the whole chain would publish the cached response again.
            let loaded = session.dataTaskPublisher(for: request)
                .failOnErrorResponse(.recoverable)
                .retry(3)
                .failOnErrorResponse(.all)

            cached
                .append(loaded)
                .removeDuplicates { $0.data == $1.data && total($0.response) == total($1.response) }
                .receive(subscriber: subscriber)
        }
    }

    /// Returns a publisher that delivers the response the URL cache holds for `request`, then the
    /// response the request loads.
    ///
    /// See ``CachedDataTaskPublisher`` for how the two are delivered and how failures are handled.
    public func cachedDataTaskPublisher(for request: URLRequest) -> CachedDataTaskPublisher {
        CachedDataTaskPublisher(request: request, session: self)
    }

    /// Returns a publisher that delivers the response the URL cache holds for `url`, then the
    /// response a request for it loads.
    public func cachedDataTaskPublisher(for url: URL) -> CachedDataTaskPublisher {
        CachedDataTaskPublisher(request: URLRequest(url: url), session: self)
    }
}

/// Whether `response` has a 2xx status, as a response other than HTTP is taken to.
private func isSuccess(_ response: URLResponse) -> Bool {
    guard let statusCode = (response as? HTTPURLResponse)?.statusCode else { return true }
    return (200..<300).contains(statusCode)
}

/// The `total` header of `response`, the element count a paginated endpoint reports.
private func total(_ response: URLResponse) -> String? {
    (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "total")
}
