import Foundation

/// Builder for the query parameters of the
/// [story endpoint](https://www.storyblok.com/docs/api/content-delivery/v2/stories/retrieve-a-single-story).
///
/// ```swift
/// let story: AnyPublisher<Story<Content>, _> = client.story("articles/hello-world") {
///     $0.fromRelease = "12345"
/// }
/// ```
public struct StoryQuery : Sendable {

    /// Omit these content fields from the response to reduce its size. Maps to `excluding_fields`.
    public var excludingFields: [String] = []

    /// Retrieve the story as it appears in the release with this id. Maps to `from_release`.
    public var fromRelease: String?

    private var additions: [URLQueryItem] = []

    public init() {}

    /// A query configured by `configure`, so that one can be written where it is passed:
    /// `StoryQuery { $0.fromRelease = "12345" }`.
    public init(_ configure: (inout StoryQuery) -> Void) {
        configure(&self)
    }

    /// Add a query parameter as given, for one this version has no entry point for, such as a
    /// parameter the API has gained since.
    ///
    /// The parameter is added to the query string after those this query generates, in the order
    /// added, and adding a name more than once sends it more than once. It replaces nothing, so
    /// add only names this library does not send itself: one it does — a parameter this query
    /// generates, or one the client sends around the query, such as `resolve_relations`,
    /// `resolve_level` or `find_by` — would go out twice, leaving the API to choose between the two.
    public mutating func parameter(_ name: String, _ value: String) {
        additions.append(URLQueryItem(name: name, value: value))
    }

    /// The query parameters this query states.
    var queryItems: [URLQueryItem] {
        var items: [URLQueryItem] = []
        if !excludingFields.isEmpty { items.append(URLQueryItem(name: "excluding_fields", value: excludingFields.joined(separator: ","))) }
        if let fromRelease { items.append(URLQueryItem(name: "from_release", value: fromRelease)) }
        return items + additions
    }
}
