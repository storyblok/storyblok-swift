import Foundation

/// Mutable store of per-rel subdecoders, keyed by lowercase UUID string.
///
/// An instance is created per request and placed in a `JSONDecoder`'s `userInfo` before
/// decoding. `StoryResponse` populates it from the `rels` array first, and then
/// `Story.init(from:)` draws from it when it encounters a UUID string in a relation field.
final class RelationStore: @unchecked Sendable {
    var decoders: [String: any Decoder] = [:]
    /// Tracks how many times each UUID is currently on the decoding call stack, used to detect
    /// and depth-limit circular references.
    var decoding: [String: Int] = [:]
    /// Maximum number of times the same UUID may appear in the decoding call stack before the
    /// relation is treated as circular. Mirrors the `resolveLevel` passed to `story(…)`.
    var resolveLevel: Int = 1
}

/// Lightweight helper that extracts only the `uuid` field from a rel entry.
private struct RelUUID: Decodable {
    let uuid: UUID
}

/// The top-level shape of a Storyblok [story endpoint](https://www.storyblok.com/docs/api/content-delivery/v2/stories/retrieve-one-story) response.
///
/// - Parameters:
///   - Content: The ``Block`` type of the primary story's content.
///
/// `StoryResponse` registers a subdecoder for each rel in the `rels` array **before** decoding
/// `story`, so that `Story.init(from:)` can lazily resolve UUID-string placeholders on demand.
struct StoryResponse<Content: Decodable>: Decodable {

    let story: Story<Content>

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let store = decoder.userInfo[.storyblokRelations] as? RelationStore,
           container.contains(.rels) {
            var rels = try container.nestedUnkeyedContainer(forKey: .rels)
            while !rels.isAtEnd {
                let subdecoder = try rels.superDecoder()
                let id = try RelUUID(from: subdecoder)
                store.decoders[id.uuid.uuidString.lowercased()] = subdecoder
            }
        }

        story = try container.decode(Story<Content>.self, forKey: .story)
    }

    private enum CodingKeys: String, CodingKey {
        case story
        case rels
    }
}
