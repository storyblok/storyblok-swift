import Foundation

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
package extension URL {
    /// Returns the URL with its query items ordered by name, and their percent encoding normalized.
    ///
    /// `URLCache` keys an entry on the request URL exactly as written, so two spellings of one request are two
    /// cache entries, and the cached value a ``Foundation/URLSession/CachedDataTaskPublisher`` looks for first is never found. They arise
    /// readily: the Content Delivery API returns the `Location` it redirects a published request to with its
    /// query items sorted by name and their values escaped.
    ///
    /// - Parameter readingPlusAsSpace: Whether a bare `+` in the query means a space, as in the `Location` the API
    ///   redirects to. In a URL built from `URLQueryItem`s, which leaves a literal plus unescaped, it does not.
    func sortingQueryItems(readingPlusAsSpace: Bool = false) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        // Percent decoding is unambiguous, so any two spellings of a value decode alike and re-encode alike —
        // except `+`, which the API writes for a space while `URLQueryItem` leaves a literal plus as it is.
        // Spelling it out first, as whichever the URL means, is what lets the two sides meet. A plus the API
        // meant literally arrives as `%2B`, so it is left alone.
        if let query = components.percentEncodedQuery {
            components.percentEncodedQuery = query.replacingOccurrences(of: "+", with: readingPlusAsSpace ? "%20" : "%2B")
        }
        guard let items = components.queryItems, items.count > 1 else { return components.url ?? self }
        // Sorted on (name, position) so repeated names keep the order their values were given in:
        // `sorted(by:)` is not itself a stable sort.
        components.queryItems = items.enumerated()
            .sorted { ($0.element.name, $0.offset) < ($1.element.name, $1.offset) }
            .map(\.element)
        // Re-encoding writes a plus literally, which the API would read back as a space. Every `+` that meant a
        // space became `%20` above, so whatever is left is a plus someone meant, and has to say so.
        if let query = components.percentEncodedQuery {
            components.percentEncodedQuery = query.replacingOccurrences(of: "+", with: "%2B")
        }
        return components.url ?? self
    }
}
