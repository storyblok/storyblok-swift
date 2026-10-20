import Foundation
import Combine
import URLSessionExtension

extension URLSession {

    /// Fetches page `number` of the offset-paginated endpoint at `path`, reading its elements out
    /// of the response body with `decode`: the copy the URL cache holds, if any, then the fresh
    /// one, as a story is fetched.
    ///
    /// The Content Delivery API pages uniformly — `page` and `per_page` parameters, a `Total`
    /// response header — so only `path`, the `queryItems` a query states and `decode` are
    /// particular to an endpoint. Everything else here applies to any of them.
    func page<Element>(
        _ number: Int,
        of path: String,
        size: Int,
        queryItems: [URLQueryItem],
        decode: @escaping (_ body: Data) throws -> [Element]
    ) -> AnyPublisher<Page<Element>, any Error> {
        var request = URLRequest(storyblok: self, path: path)
        request.url!.append(queryItems: [
            URLQueryItem(name: "page", value: String(number)),
            URLQueryItem(name: "per_page", value: String(size)),
        ] + queryItems)
        // One spelling per request, so the cache probe finds what the previous fetch stored.
        request.url = request.url!.sortingQueryItems()

        return cachedDataTaskPublisher(for: request)
            .tryMap { data, response in
                let total = (response as? HTTPURLResponse)
                    .flatMap { $0.value(forHTTPHeaderField: "Total") }
                    .flatMap(Int.init)
                return Page(try decode(data), number: number, size: size, total: total)
            }
            .eraseToAnyPublisher()
    }
}
