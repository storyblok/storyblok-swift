import Foundation
import Combine

extension URLSession {

    /// A publisher that delivers one page of a paginated endpoint, fetched by the upstream
    /// publisher it is given.
    ///
    /// Create one with ``Foundation/URLSession/pagePublisher(for:page:perPage:upstream:elements:)``.
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
    /// let tags = storyblok.pagePublisher(for: request, page: 1, perPage: 100) { body in
    ///     try JSONDecoder().decode([String: [Tag]].self, from: body)["internal_tags"] ?? []
    /// }
    /// ```
    ///
    /// The upstream publisher decides how the page is fetched:
    ///
    /// - `URLSession.DataTaskPublisher.init`, the default, fetches it fresh each time, as a
    ///   server or a script wants.
    /// - `URLSession.CachedDataTaskPublisher.init` publishes the copy the URL cache holds first,
    ///   then the fresh one, as a ``CachedDataTaskPublisher`` does, so an app can show a page at
    ///   once.
    ///
    /// Any error response fails the publisher with an ``Api/ResponseError``, whichever upstream
    /// fetched it, and so does a body that `elements` cannot read.
    public struct PagePublisher<Upstream : Publisher, Element> : Publisher
    where Upstream.Output == (data: Data, response: URLResponse) {

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

        private let upstream: (URLRequest, URLSession) -> Upstream
        private let elements: (_ body: Data) throws -> [Element]

        /// Creates a publisher that delivers page `page` of the endpoint `request` addresses,
        /// `perPage` elements to a page, fetched with the publisher `upstream` creates.
        ///
        /// - Parameters:
        ///   - request: The request for the endpoint, without `page` or `per_page`.
        ///   - page: The page to fetch, counting from 1.
        ///   - perPage: Elements per page, sent as `per_page`. The APIs cap this, at 100 for the
        ///     Content Delivery API's stories and 1000 elsewhere.
        ///   - session: The session that performs the request.
        ///   - upstream: Creates the publisher that fetches the page, given the paged request and
        ///     `session`, such as `URLSession.DataTaskPublisher.init` or
        ///     `URLSession.CachedDataTaskPublisher.init`.
        ///   - elements: Reads the page's elements out of a response body.
        public init(
            request: URLRequest,
            page: Int,
            perPage: Int,
            session: URLSession,
            upstream: @escaping (URLRequest, URLSession) -> Upstream,
            elements: @escaping (_ body: Data) throws -> [Element]
        ) {
            self.request = request
            self.page = page
            self.perPage = perPage
            self.session = session
            self.upstream = upstream
            self.elements = elements
        }

        public func receive<S : Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
            var request = request
            request.url!.append(queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage)),
            ])
            // One spelling per request, so a cache probe finds what the previous fetch stored.
            request.url = request.url!.sortingQueryItems()

            let page = page, perPage = perPage, elements = elements
            upstream(request, session)
                // A plain data task publishes an error response like any other, and its body
                // would otherwise reach `elements`.
                .failOnErrorResponse(.all)
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
    /// See ``PagePublisher`` for how the page is requested and delivered.
    ///
    /// - Parameters:
    ///   - request: The request for the endpoint, without `page` or `per_page`.
    ///   - page: The page to fetch, counting from 1.
    ///   - perPage: Elements per page, sent as `per_page`. The APIs cap this, at 100 for the
    ///     Content Delivery API's stories and 1000 elsewhere.
    ///   - upstream: Creates the publisher that fetches the page. Defaults to
    ///     `URLSession.DataTaskPublisher.init`, which fetches it fresh; pass
    ///     `URLSession.CachedDataTaskPublisher.init` to publish the cached copy first.
    ///   - elements: Reads the page's elements out of a response body.
    public func pagePublisher<Upstream : Publisher, Element>(
        for request: URLRequest,
        page: Int,
        perPage: Int,
        upstream: @escaping (URLRequest, URLSession) -> Upstream = URLSession.DataTaskPublisher.init,
        elements: @escaping (_ body: Data) throws -> [Element]
    ) -> PagePublisher<Upstream, Element> where Upstream.Output == (data: Data, response: URLResponse) {
        PagePublisher(request: request, page: page, perPage: perPage, session: self, upstream: upstream, elements: elements)
    }
}
