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
}
