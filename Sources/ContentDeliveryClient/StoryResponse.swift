import Foundation

/// Mutable cache of resolved story relations, keyed by lowercase UUID string.
///
/// An instance is created per request and placed in a `JSONDecoder`'s `userInfo` before
/// decoding. `StoryResponse` populates it from the `rels` array first, and then
/// `Story.init(from:)` draws from it when it encounters a UUID string in a relation field.
final class RelationStore: @unchecked Sendable {
    var stories: [String: Any] = [:]
}

/// The top-level shape of a Storyblok [story endpoint](https://www.storyblok.com/docs/api/content-delivery/v2/stories/retrieve-one-story) response.
///
/// - Parameters:
///   - T: The ``Block`` type of the primary story's content.
///
/// `StoryResponse` populates the ``RelationStore`` from `rels` **before** decoding `story`,
/// so that `Story.init(from:)` can transparently resolve UUID-string placeholders.
/// A rel that cannot be decoded as `Story<T>` throws a `DecodingError`.
struct StoryResponse<Content: Decodable, Library: Decodable>: Decodable {

    let story: Story<Content>

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let store = decoder.userInfo[.storyblokRelations] as? RelationStore,
           container.contains(.rels) {
            var rels = try container.nestedUnkeyedContainer(forKey: .rels)
            while !rels.isAtEnd {
                let rel = try rels.decode(Story<Library>.self)
                store.stories[rel.uuid.uuidString.lowercased()] = rel
            }
        }

        story = try container.decode(Story<Content>.self, forKey: .story)
    }

    private enum CodingKeys: String, CodingKey {
        case story
        case rels
    }
}
