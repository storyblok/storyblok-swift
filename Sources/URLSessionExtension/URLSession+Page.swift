import Foundation
import Combine

extension URLSession {

    /// Returns a publisher that delivers one page of the paginated endpoint `request` addresses,
    /// reading its elements out of the response body with `elements`.
    ///
    /// The Content Delivery and Management APIs page the same way: `page` and `per_page` query
    /// parameters, and a `total` response header counting the elements across all pages. This adds
    /// the two parameters to `request` and reads `total` into the ``Page``, which says whether there
    /// is a page after this one:
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
    /// The page is fetched as ``cachedDataTaskPublisher(for:)-(URLRequest)`` fetches a response: the
    /// copy the URL cache holds, if any, then the fresh one, retrying transient failures.
    ///
    /// - Parameters:
    ///   - request: The request for the endpoint, without `page` or `per_page`.
    ///   - page: The page to fetch, counting from 1.
    ///   - perPage: Elements per page, sent as `per_page`. The APIs cap this, at 100 for the
    ///     Content Delivery API's stories and 1000 elsewhere.
    ///   - elements: Reads the page's elements out of a response body.
    public func pagePublisher<Element>(
        for request: URLRequest,
        page: Int,
        perPage: Int,
        elements: @escaping (_ body: Data) throws -> [Element]
    ) -> AnyPublisher<Page<Element>, any Error> {
        var request = request
        request.url!.append(queryItems: [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
        ])
        // One spelling per request, so the cache probe finds what the previous fetch stored.
        request.url = request.url!.sortingQueryItems()

        return cachedDataTaskPublisher(for: request)
            .tryMap { data, response in
                let total = (response as? HTTPURLResponse)
                    .flatMap { $0.value(forHTTPHeaderField: "total") }
                    .flatMap(Int.init)
                return Page(try elements(data), number: page, size: perPage, total: total)
            }
            .eraseToAnyPublisher()
    }
}
