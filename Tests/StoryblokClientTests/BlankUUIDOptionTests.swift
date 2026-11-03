import Foundation
import Testing
@testable import StoryblokClient

@BlockLibrary
enum OptionBlock {
    case promo(Promo)
    case banner(category: UUID?)

    struct Promo {
        let category: UUID?
        let featured: UUID
    }
}

/// A single-option field sourced from stories, with no story selected, which Storyblok sends as `""`.
@Suite
struct BlankUUIDOptionTests {

    private static let uuid = "11111111-1111-1111-1111-111111111111"

    private func decode<T: Decodable>(_ content: String, as type: T.Type = OptionBlock.self) throws -> T {
        try StoryblokClient<OptionBlock>.decoder(resolveLevel: 1).decode(T.self, from: Data(content.utf8))
    }

    @Test
    func `a blank optional UUID decodes as nil`() throws {
        let promo = try decode(#"{"component": "promo", "category": "", "featured": "\#(Self.uuid)"}"#, as: OptionBlock.Promo.self)

        #expect(promo.category == nil)
    }

    @Test
    func `a blank optional UUID in a labeled value decodes as nil`() throws {
        guard case .banner(let category) = try decode(#"{"component": "banner", "category": ""}"#) else {
            Issue.record("expected .banner")
            return
        }
        #expect(category == nil)
    }

    @Test
    func `a selected optional UUID still decodes`() throws {
        let promo = try decode(#"{"component": "promo", "category": "\#(Self.uuid)", "featured": "\#(Self.uuid)"}"#, as: OptionBlock.Promo.self)

        #expect(promo.category == UUID(uuidString: Self.uuid))
    }

    @Test
    func `an invalid optional UUID still throws`() {
        #expect(throws: DecodingError.self) {
            try decode(#"{"component": "promo", "category": "nope", "featured": "\#(Self.uuid)"}"#, as: OptionBlock.Promo.self)
        }
    }

    @Test
    func `a blank required UUID still throws`() {
        #expect(throws: DecodingError.self) {
            try decode(#"{"component": "promo", "category": null, "featured": ""}"#, as: OptionBlock.Promo.self)
        }
    }

    @Test
    func `a decoder other than the client's is unaffected`() {
        struct Plain: Decodable { let category: UUID? }

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Plain.self, from: Data(#"{"category": ""}"#.utf8))
        }
    }

    @Test
    func `a decoder whose superDecoder throws still throws a decoding error`() {
        struct Plain: Decodable { let category: UUID? }

        #expect(throws: DecodingError.self) {
            try Plain(from: StringsDecoder(values: ["category": ""]))
        }
    }
}

/// A decoder over string values whose `superDecoder(forKey:)` throws, as a custom decoder's may.
private struct StringsDecoder: Decoder {
    struct Unsupported: Error {}

    let values: [String: String]
    var codingPath: [any CodingKey] { [] }
    var userInfo: [CodingUserInfoKey: Any] { [:] }

    func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(Container(values: values))
    }
    func unkeyedContainer() throws -> any UnkeyedDecodingContainer { throw Unsupported() }
    func singleValueContainer() throws -> any SingleValueDecodingContainer { throw Unsupported() }

    struct Container<Key: CodingKey>: KeyedDecodingContainerProtocol {
        let values: [String: String]
        var codingPath: [any CodingKey] { [] }
        var allKeys: [Key] { values.keys.compactMap(Key.init(stringValue:)) }

        func contains(_ key: Key) -> Bool { values[key.stringValue] != nil }
        func decodeNil(forKey key: Key) -> Bool { false }
        func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
            guard let value = values[key.stringValue] as? T else {
                throw DecodingError.typeMismatch(T.self, .init(codingPath: [key], debugDescription: "Only strings"))
            }
            return value
        }
        func nestedContainer<NestedKey: CodingKey>(
            keyedBy type: NestedKey.Type,
            forKey key: Key
        ) throws -> KeyedDecodingContainer<NestedKey> { throw Unsupported() }
        func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer { throw Unsupported() }
        func superDecoder() throws -> any Decoder { throw Unsupported() }
        func superDecoder(forKey key: Key) throws -> any Decoder { throw Unsupported() }
    }
}
