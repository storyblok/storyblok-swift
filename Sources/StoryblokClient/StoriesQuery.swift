import Foundation

/// How a `sort_by` field is ordered, for a field whose Swift type cannot settle it.
///
/// Storyblok serialises a number field's value as text, so a field holding a number is as likely
/// to be a `String` as an `Int`. Where the type says, the ordering is chosen for you.
public enum SortAs : Sendable {
    /// Order numerically, without a decimal point, so that `100` sorts after `99`. Appends `:int`.
    case wholeNumber
    /// Order numerically, with a decimal point. Appends `:float`.
    case decimal
    /// Order as text, the API's default, which orders an ISO-8601 date chronologically.
    case text

    var suffix: String? {
        switch self {
            case .wholeNumber: ":int"
            case .decimal: ":float"
            case .text: nil
        }
    }
}

/// Which end of the order a field sorts towards.
public enum SortDirection : String, Sendable {
    case ascending = "asc"
    case descending = "desc"
}

/// Builder for the query parameters of the
/// [retrieve multiple stories](https://www.storyblok.com/docs/api/content-delivery/v2/stories/retrieve-multiple-stories)
/// endpoint.
///
/// Every documented parameter has a typed entry point. Fields of your own content are addressed
/// by key path, which fixes the field's Swift type — so an operation the field cannot support does
/// not compile — and resolves to the name Storyblok knows it by via ``QueryableContent``.
///
/// ```swift
/// client.stories { (q: inout StoriesQuery<Block.Post>) in
///     q.startsWith = "articles/"
///     q.sort(by: \.title)
///     q.filter {
///         $0.title.like("*space*")
///         $0.date > lastMonth
///     }
/// }
/// ```
///
/// `content_type` needs no entry point: it comes from ``QueryableContent/technicalName``, since a
/// content type and the struct modelling it are one to one.
public struct StoriesQuery<Content : QueryableContent> : Sendable {

    /// Filter by the full-slug prefix, e.g. `articles/`, to retrieve the stories of one folder. Maps to `starts_with`.
    public var startsWith: String?

    /// Search across all content fields. Maps to `search_term`.
    public var searchTerm: String?

    /// Retrieve only start pages (`true`) or only non-start pages (`false`). Maps to `is_startpage`.
    public var isStartPage: Bool?

    /// Retrieve the stories matching these full slugs; supports `*` wildcards. Maps to `by_slugs`.
    public var bySlugs: [String] = []

    /// Exclude the stories matching these full slugs; supports `*` wildcards. Maps to `excluding_slugs`.
    public var excludingSlugs: [String] = []

    /// Retrieve the stories with these UUIDs, in the API's own order. Maps to `by_uuids`.
    public var byUuids: [UUID] = []

    /// Retrieve the stories with these UUIDs, preserving the order given here. Maps to `by_uuids_ordered`.
    public var byUuidsOrdered: [UUID] = []

    /// Exclude the stories with these ids. Maps to `excluding_ids`.
    public var excludingIds: [Int64] = []

    /// Retrieve only stories carrying *all* of these tags. Maps to `with_tag`.
    public var withTag: [String] = []

    /// Omit these content fields from the response to reduce its size. Maps to `excluding_fields`.
    public var excludingFields: [String] = []

    /// Retrieve the stories as they appear in the release with this id. Maps to `from_release`.
    public var fromRelease: String?

    /// Retrieve stories first published after this date. Maps to `first_published_at_gt`.
    public var firstPublishedAfter: Date?

    /// Retrieve stories first published before this date. Maps to `first_published_at_lt`.
    public var firstPublishedBefore: Date?

    /// Retrieve stories published after this date. Maps to `published_at_gt`.
    public var publishedAfter: Date?

    /// Retrieve stories published before this date. Maps to `published_at_lt`.
    public var publishedBefore: Date?

    /// Retrieve stories updated after this date. Maps to `updated_at_gt`.
    public var updatedAfter: Date?

    /// Retrieve stories updated before this date. Maps to `updated_at_lt`.
    public var updatedBefore: Date?

    private var sorts: [String] = []
    private var filters: [Filter<Content>] = []
    private var additions: [URLQueryItem] = []

    public init() {}

    /// A query configured by `configure`, so that one can be written where it is passed:
    /// `StoriesQuery { $0.startsWith = "articles/" }`.
    public init(_ configure: (inout StoriesQuery) -> Void) {
        configure(&self)
    }
}

// MARK: - Sorting

extension StoriesQuery {

    /// Sort by a content field. The `content.` prefix the API requires is added for you.
    ///
    /// A whole-number field is ordered numerically, so that `100` sorts after `99`; a decimal
    /// field likewise; every other field as text, which orders an ISO-8601 date chronologically.
    /// Call repeatedly to sort by several fields; they apply in call order.
    public mutating func sort<Value : BinaryInteger>(
        by field: KeyPath<Content, Value>,
        _ direction: SortDirection = .ascending
    ) {
        sort(field, direction, .wholeNumber)
    }

    /// Sort by a decimal content field, ordered numerically.
    public mutating func sort(by field: KeyPath<Content, Double>, _ direction: SortDirection = .ascending) {
        sort(field, direction, .decimal)
    }

    /// Sort by a content field, ordered as text.
    public mutating func sort<Value>(by field: KeyPath<Content, Value>, _ direction: SortDirection = .ascending) {
        sort(field, direction, .text)
    }

    /// Sort by a content field, stating the ordering rather than taking it from the field's type.
    ///
    /// Needed where Storyblok holds a number in a text field: the property is a `String`, so its
    /// type cannot say that `100` should sort after `99`.
    public mutating func sort<Value>(
        by field: KeyPath<Content, Value>,
        _ direction: SortDirection = .ascending,
        as sortAs: SortAs
    ) {
        sort(field, direction, sortAs)
    }

    /// Sort by an attribute of the ``Story`` itself rather than by a field of its content.
    ///
    /// Only some attributes are sortable. The API answers the rest with `Not sortable by this
    /// column` rather than this library second-guessing which those are.
    public mutating func sort(byAttribute attribute: StoryAttribute, _ direction: SortDirection = .ascending) {
        sorts.append("\(attribute.rawValue):\(direction.rawValue)")
    }

    private mutating func sort(_ field: AnyKeyPath, _ direction: SortDirection, _ sortAs: SortAs) {
        sorts.append("content.\(Content.fieldName(for: field)):\(direction.rawValue)\(sortAs.suffix ?? "")")
    }
}

// MARK: - Filtering

extension StoriesQuery {

    /// Add [filter query](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries)
    /// conditions, addressing fields by key path.
    ///
    /// A key path addresses one of `Content`'s own fields. [Nested blocks and
    /// fields](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/nested-blocks-and-fields),
    /// which the API addresses with a dotted path, have no entry point — write those out with
    /// ``parameter(_:_:)``.
    public mutating func filter(@FilterBuilder<Content> _ conditions: (Fields<Content>) -> [Filter<Content>]) {
        filters.append(contentsOf: conditions(Fields()))
    }
}

// MARK: - Escape hatch

extension StoriesQuery {

    /// Add a query parameter as given, for one this version has no entry point for — a parameter
    /// the API has gained since, or a filter on a nested field.
    ///
    /// The parameter is added to the query string after those this query generates, in the order
    /// added, and adding a name more than once sends it more than once. It replaces nothing, so
    /// add only names this library does not send itself: one it does — a parameter this query
    /// generates, such as `sort_by`, or `content_type` when `Content` is one component, or one the
    /// client sends around the query, such as `page`, `per_page` or `resolve_relations` — would go
    /// out twice, leaving the API to choose between the two.
    public mutating func parameter(_ name: String, _ value: String) {
        additions.append(URLQueryItem(name: name, value: value))
    }
}

// MARK: - Wire form

extension StoriesQuery {

    /// The query parameters this query states, in a stable order so that two queries asking the
    /// same thing compare equal: StoryblokUI's `Stories` starts again from page 1 only when they
    /// differ. The request URL is sorted again when it is built, so the order sent does not
    /// depend on this.
    package var queryItems: [URLQueryItem] {
        var items: [String: String] = [:]

        if let technicalName = Content.technicalName { items["content_type"] = technicalName }
        if let startsWith { items["starts_with"] = startsWith }
        if let searchTerm { items["search_term"] = searchTerm }
        if let isStartPage { items["is_startpage"] = String(isStartPage) }
        if !bySlugs.isEmpty { items["by_slugs"] = bySlugs.joined(separator: ",") }
        if !excludingSlugs.isEmpty { items["excluding_slugs"] = excludingSlugs.joined(separator: ",") }
        if !byUuids.isEmpty { items["by_uuids"] = byUuids.map(\.wireValue).joined(separator: ",") }
        if !byUuidsOrdered.isEmpty { items["by_uuids_ordered"] = byUuidsOrdered.map(\.wireValue).joined(separator: ",") }
        if !excludingIds.isEmpty { items["excluding_ids"] = excludingIds.map(String.init).joined(separator: ",") }
        if !withTag.isEmpty { items["with_tag"] = withTag.joined(separator: ",") }
        if !excludingFields.isEmpty { items["excluding_fields"] = excludingFields.joined(separator: ",") }
        if let fromRelease { items["from_release"] = fromRelease }
        if let firstPublishedAfter { items["first_published_at_gt"] = firstPublishedAfter.wireValue }
        if let firstPublishedBefore { items["first_published_at_lt"] = firstPublishedBefore.wireValue }
        if let publishedAfter { items["published_at_gt"] = publishedAfter.wireValue }
        if let publishedBefore { items["published_at_lt"] = publishedBefore.wireValue }
        if let updatedAfter { items["updated_at_gt"] = updatedAfter.wireValue }
        if let updatedBefore { items["updated_at_lt"] = updatedBefore.wireValue }
        if !sorts.isEmpty { items["sort_by"] = sorts.joined(separator: ",") }

        for filter in filters {
            items["filter_query[\(filter.name)][\(filter.operation)]"] = filter.value
        }

        return items.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) } + additions
    }
}

extension UUID {
    fileprivate var wireValue: String { uuidString.lowercased() }
}

extension Date {
    /// The date as the API reads it in a query parameter or a filter condition.
    var wireValue: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: self)
    }
}
