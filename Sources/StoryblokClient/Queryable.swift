import Foundation
import Logging

private let log = Logger(label: "com.storyblok.StoryblokClient")

/// A content type whose fields can be addressed by key path in a ``StoriesQuery``.
///
/// The ``BlockLibrary()`` macro conforms each nested content `struct` for you, deriving
/// ``technicalName`` from the enum case that carries it and ``fieldNames`` from the struct's
/// `CodingKeys`. A hand-written content type can conform manually.
///
/// A component modelled with labeled values, such as `case header(altTitle: String)`, has no
/// type of its own to conform. To query it by its fields, model it with a nested struct instead.
///
/// Conformance is what lets a query say `\.price` instead of `"price"`: the key path fixes the
/// field's Swift type, so the compiler can reject an operation the field cannot support, and the
/// lookup here supplies the name Storyblok knows it by.
public protocol QueryableContent : Decodable {

    /// The component's technical name in Storyblok, sent as `content_type`.
    ///
    /// `nil` for a type that stands for several components — a whole ``BlockLibrary`` — which
    /// sends no `content_type` and so matches stories of every type.
    static var technicalName: String? { get }

    /// The name Storyblok knows each field by, keyed by its key path.
    ///
    /// A field whose JSON name differs from the Swift property is named by the struct's
    /// `CodingKeys`, and that mapping is what appears here.
    ///
    /// A key path missing from the table, such as a nested path, is sent under its Swift name,
    /// `price` or `author.name`, and a warning is logged. That is the right name when `CodingKeys`
    /// does not change it, so a hand-written conformance need only list the fields it renames. A
    /// computed property is no Storyblok field, and a stripped binary cannot name one: a sort or
    /// condition on a key path with no readable name is left out, and an error is logged.
    static var fieldNames: [AnyKeyPath: String] { get }
}

extension QueryableContent {

    public static var technicalName: String? { nil }
    public static var fieldNames: [AnyKeyPath: String] { [:] }

    /// The name Storyblok knows `keyPath` by, or its Swift name when ``fieldNames`` does not say,
    /// or `nil` when neither can be had.
    static func fieldName(for keyPath: AnyKeyPath) -> String? {
        if let name = fieldNames[keyPath] { return name }
        let description = String(describing: keyPath)
        guard let name = swiftName(fromDescription: description) else {
            log.error("\(Self.self).fieldNames has no entry for \(description), and no name can be read from it, so it is left out of the query.")
            return nil
        }
        log.warning("\(Self.self).fieldNames has no entry for \(description), so it is sent as \"\(name)\".")
        return name
    }

    /// The property path a key path's description names, `price` or `author.name`, or `nil` when
    /// it names none.
    ///
    /// A key path describes itself as `\Root.path`. A stored property's name is always there, but
    /// a computed property's is only while the binary keeps its symbols: a stripped one describes
    /// it as `<computed 0x… (Bool)>`, which is no field name.
    static func swiftName(fromDescription description: String) -> String? {
        let root = "\\\(String(describing: Self.self))."
        guard description.hasPrefix(root) else { return nil }
        let path = description.dropFirst(root.count)
        guard !path.isEmpty, !path.contains(where: { "<>()[]".contains($0) || $0.isWhitespace }) else { return nil }
        return String(path)
    }
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
