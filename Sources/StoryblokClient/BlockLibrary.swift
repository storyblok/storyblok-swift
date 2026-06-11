import Foundation

/// The set of Storyblok components a ``StoryblokClient`` can decode.
///
/// A block library enumerates your space's components and determines which ``Story`` relations
/// the client resolves. Conform an `enum` by applying the ``BlockLibrary()`` macro, which
/// synthesizes ``relations`` and the `Decodable` conformance from the enum's cases:
///
/// ```swift
/// @BlockLibrary
/// enum Content {
///     case article(author: Story<Content>)
///     case popular(articles: [Story<Content>])
/// }
/// // Content.relations == "article.author,popular.articles"
/// ```
///
/// You can also conform a type manually (for example a single `struct` representing one
/// component) by implementing `Decodable` and, when relations need resolving, ``relations``.
public protocol BlockLibrary : Decodable {

    /// Comma-separated `component.field` pairs for the `resolve_relations` API parameter.
    ///
    /// The value is ready to pass directly as the `resolve_relations` query parameter value.
    /// An empty string means no relations need resolving.
    static var relations: String { get }
}

extension BlockLibrary {
    public static var relations: String { "" }
}

/// Conforms an `enum` to ``BlockLibrary`` and synthesizes its decoding from the enum's cases.
///
/// Each case maps to a Storyblok component: the case name is matched against the component's
/// technical name (override the mapping with a top-level `CodingKeys` enum). A case may carry
/// either a single unlabeled nested-struct associated value (which decodes the whole content
/// object) or labeled associated values (which decode individual fields). A parameterless
/// `case unknown` acts as a catch-all so unrecognised components decode without throwing.
///
/// Applied to an `enum`, this macro:
///
/// - Adds a `relations` static property built from the enum's case names and the labels of any
///   ``Story``-typed associated values (including ``Story`` fields of nested structs). The format
///   is `componentName.fieldName` pairs joined by commas, sorted alphabetically, ready for use as
///   the `resolve_relations` API parameter.
/// - Synthesizes an `init(from:)` decoder that dispatches on the `component` field, plus the
///   `CodingKeys` enums it needs.
/// - Adds a conformance to ``BlockLibrary`` if the type does not already declare it.
///
/// ```swift
/// @BlockLibrary
/// enum Content {
///     case article(author: Story<Content>)
///     case popular(articles: [Story<Content>])
///     case text(value: String)
///     case unknown
/// }
/// ```
///
/// Expands to add, among other members:
/// ```swift
/// enum Content {
///     // ... existing members ...
///     nonisolated static let relations: String = "article.author,popular.articles"
///     nonisolated init(from decoder: any Decoder) throws { /* dispatches on `component` */ }
/// }
/// nonisolated extension Content: BlockLibrary {}
/// ```
@attached(member, names: named(relations), named(init), named(CodingKeys), arbitrary)
@attached(extension, conformances: BlockLibrary)
public macro BlockLibrary() = #externalMacro(
    module: "StoryblokClientMacros",
    type: "BlockLibraryMacro"
)

internal extension CodingUserInfoKey {

    /// The [`CodingUserInfoKey`](https://developer.apple.com/documentation/swift/codinguserinfokey) used
    /// to pass a ``RelationStore`` through a `JSONDecoder`'s
    /// [`userInfo`](https://developer.apple.com/documentation/foundation/jsondecoder/userinfo).
    ///
    /// The stored value is a ``RelationStore`` instance.
    static let storyblokRelations = CodingUserInfoKey(rawValue: "com.storyblok.relations")!
}


