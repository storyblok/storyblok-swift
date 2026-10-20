import Foundation

/// A content type whose fields can be addressed by key path in a ``StoriesQuery``.
///
/// The ``BlockLibrary()`` macro conforms each nested content `struct` for you, deriving
/// ``technicalName`` from the enum case that carries it and ``fieldNames`` from the struct's
/// `CodingKeys`. A hand-written content type can conform manually.
///
/// Conformance is what lets a query say `\.price` instead of `"price"`: the key path fixes the
/// field's Swift type, so the compiler can reject an operation the field cannot support, and the
/// lookup here supplies the name Storyblok knows it by.
///
/// Content must be `Sendable`: a ``Page`` of stories is built on the URL session's queue and
/// received on the caller's, typically the main actor. Decoded content is a value type in
/// practice, so this costs nothing in the normal case.
public protocol QueryableContent : Decodable, Sendable {

    /// The component's technical name in Storyblok, sent as `content_type`.
    ///
    /// `nil` for a type that stands for several components — a whole ``BlockLibrary`` — which
    /// sends no `content_type` and so matches stories of every type.
    static var technicalName: String? { get }

    /// The name Storyblok knows each field by, keyed by its key path.
    ///
    /// A field whose JSON name differs from the Swift property is named by the struct's
    /// `CodingKeys`, and that mapping is what appears here.
    static var fieldNames: [AnyKeyPath: String] { get }
}

extension QueryableContent {

    public static var technicalName: String? { nil }
    public static var fieldNames: [AnyKeyPath: String] { [:] }

    /// The name Storyblok knows `keyPath` by, falling back to nothing when the type does not
    /// describe its fields — a hand-written conformance need only supply what it uses.
    static func fieldName(for keyPath: AnyKeyPath) -> String? { fieldNames[keyPath] }
}

// MARK: - Story attributes

/// An attribute of the ``Story`` itself, as opposed to a field of its content.
///
/// A fixed set, since ``Story`` is this library's own type — where content fields are addressed by
/// key path, these are named directly. Key paths cannot serve here: `\Story<A>.publishedAt` and
/// `\Story<B>.publishedAt` are different key paths, so no single table could match them.
///
/// Only some attributes are sortable. The API answers the rest with `Not sortable by this column`
/// rather than this library second-guessing which those are.
public enum StoryAttribute : String, Sendable {
    case id
    case uuid
    case name
    case slug
    case fullSlug = "full_slug"
    case createdAt = "created_at"
    case publishedAt = "published_at"
    case firstPublishedAt = "first_published_at"
    case updatedAt = "updated_at"
    case sortByDate = "sort_by_date"
    case position
    case isStartPage = "is_startpage"
    case parentId = "parent_id"
    case groupId = "group_id"
    case language = "lang"
    case path
}
