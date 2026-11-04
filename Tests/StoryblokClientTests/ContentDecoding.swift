import Foundation
@testable import StoryblokClient

/// Decodes a value through `ContentDecoder`, as `ContentResponse` decodes a response's content.
struct ThroughContentDecoder<Value: Decodable>: Decodable {
    let value: Value

    init(from decoder: any Decoder) throws {
        value = try Value(from: ContentDecoder(base: decoder))
    }
}

extension JSONDecoder {
    /// Decodes `type` from `data` as ``StoryblokClient`` decodes a response's content.
    func decodeContent<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decode(ThroughContentDecoder<T>.self, from: data).value
    }
}
