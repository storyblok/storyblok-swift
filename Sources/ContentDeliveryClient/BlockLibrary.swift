import Foundation

/// Base protocol for all Storyblok blocks.
///
/// Conform to this protocol to define a content type that maps to one or more Storyblok
/// component types. Use the ``BlockLibrary()`` macro on an `enum` to automatically synthesize
/// the ``relations`` property from the enum's case names and associated value labels.
///
/// ```swift
/// @BlockLibrary
/// enum Content {
///     case article(author: Story<Author>)
///     case popular(articles: [Story<Article>])
/// }
/// // Content.relations == "article.author,popular.articles"
/// ```
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

/// Conforms an `enum` to ``Block`` and synthesizes a `relations` property from its cases.
///
/// Applied to an `enum`, this macro:
///
/// - Adds a `relations` static property built from the enum's case names and the labels of
///   any `Story`-typed associated values. The format is `caseName.fieldLabel` pairs joined by
///   commas, sorted alphabetically, ready for use as the `resolve_relations` API parameter.
/// - Adds a conformance to ``Block`` if the type does not already declare it.
///
/// ```swift
/// @BlockLibrary
/// enum Content {
///     case article(author: Story<Author>)
///     case popular(articles: [Story<Article>])
///     case text(String)
/// }
/// ```
///
/// Expands to:
/// ```swift
/// enum Content {
///     // ... existing members ...
///     static let relations: String = "article.author,popular.articles"
/// }
/// extension Content: Block {}
/// ```
@attached(member, names: named(relations), named(init), named(CodingKeys), arbitrary)
@attached(extension, conformances: BlockLibrary)
public macro BlockLibrary() = #externalMacro(
    module: "ContentDeliveryClientMacros",
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


