import Foundation
import Combine

extension URLSession {

    /// A publisher that delivers one page of a paginated endpoint: the copy the URL cache holds,
    /// then the copy the request loads.
    ///
    /// Create one with ``Foundation/URLSession/cachedPagePublisher(for:page:perPage:elements:)``.
    ///
    /// The Content Delivery and Management APIs page the same way: `page` and `per_page` query
    /// parameters, and a `total` response header counting the elements across all pages. The
    /// publisher adds the two parameters to ``request`` and reads `total` into the ``Page``, which
    /// says whether there is a page after this one:
    ///
    /// ```swift
    /// struct Tag: Decodable, Identifiable {
    ///     let name: String
    ///     var id: String { name }
    /// }
    ///
    /// let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/internal_tags")
    /// let tags = storyblok.cachedPagePublisher(for: request, page: 1, perPage: 100) { body in
    ///     try JSONDecoder().decode([String: [Tag]].self, from: body)["internal_tags"] ?? []
    /// }
    /// ```
    ///
    /// The page is fetched as a ``CachedDataTaskPublisher`` fetches a response, so it can arrive
    /// twice, the cached copy first: keep the last copy received. Transient failures are retried,
    /// and a failure ends the publisher after the cached copy, if there was one. A body that
    /// `elements` cannot read fails it too.
    public struct CachedPagePublisher<Element> : Publisher {

        public typealias Output = Page<Element>
        public typealias Failure = any Error

        /// The request for the endpoint, which the publisher adds `page` and `per_page` to.
        public let request: URLRequest

        /// The page to fetch, counting from 1.
        public let page: Int

        /// Elements per page, sent as `per_page`.
        public let perPage: Int

        /// The session that performs the request.
        public let session: URLSession

        private let elements: (_ body: Data) throws -> [Element]

        /// Creates a publisher that delivers page `page` of the endpoint `request` addresses,
        /// `perPage` elements to a page, as `session` loads it.
        ///
        /// - Parameters:
        ///   - request: The request for the endpoint, without `page` or `per_page`.
        ///   - page: The page to fetch, counting from 1.
        ///   - perPage: Elements per page, sent as `per_page`. The APIs cap this, at 100 for the
        ///     Content Delivery API's stories and 1000 elsewhere.
        ///   - session: The session that performs the request.
        ///   - elements: Reads the page's elements out of a response body.
        public init(
            request: URLRequest,
            page: Int,
            perPage: Int,
            session: URLSession,
            elements: @escaping (_ body: Data) throws -> [Element]
        ) {
            self.request = request
            self.page = page
            self.perPage = perPage
            self.session = session
            self.elements = elements
        }

        public func receive<S : Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            var request = request
            request.url!.append(queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage)),
            ])
            // One spelling per request, so the cache probe finds what the previous fetch stored.
            request.url = request.url!.sortingQueryItems()

            let page = page, perPage = perPage, elements = elements
            session.cachedDataTaskPublisher(for: request)
                .tryMap { data, response in
                    let total = (response as? HTTPURLResponse)
                        .flatMap { $0.value(forHTTPHeaderField: "total") }
                        .flatMap(Int.init)
                    return Page(try elements(data), number: page, size: perPage, total: total)
                }
                .receive(subscriber: subscriber)
        }
    }

    /// Returns a publisher that delivers one page of the paginated endpoint `request` addresses,
    /// reading its elements out of the response body with `elements`.
    ///
    /// See ``CachedPagePublisher`` for how the page is requested and delivered.
    ///
    /// - Parameters:
    ///   - request: The request for the endpoint, without `page` or `per_page`.
    ///   - page: The page to fetch, counting from 1.
    ///   - perPage: Elements per page, sent as `per_page`. The APIs cap this, at 100 for the
    ///     Content Delivery API's stories and 1000 elsewhere.
    ///   - elements: Reads the page's elements out of a response body.
    public func cachedPagePublisher<Element>(
        for request: URLRequest,
        page: Int,
        perPage: Int,
        elements: @escaping (_ body: Data) throws -> [Element]
    ) -> CachedPagePublisher<Element> {
        CachedPagePublisher(request: request, page: page, perPage: perPage, session: self, elements: elements)
    }
}
