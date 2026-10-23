import Testing
import Foundation
import StoryblokClient

/// A value no `Sendable` checking can vouch for, as content may hold.
final class Counter : Decodable {
    var count = 0
}

/// A block library whose content holds a non-`Sendable` value. `@BlockLibrary` conforms it, and
/// its nested struct, to `QueryableContent`, so this compiles only while that protocol does not
/// require `Sendable`.
@BlockLibrary
enum MutableLibrary : Decodable {
    case widget(Widget)

    struct Widget : Decodable {
        let counter: Counter
    }
}

/// A block library whose content has a lazy property, which a key path cannot refer to. This
/// compiles only while `@StoryblokContent` leaves lazy properties out of `fieldNames`.
@BlockLibrary
enum LazyLibrary : Decodable {
    case note(Note)

    struct Note : Decodable {
        let title: String
        lazy var normalized: String = title.lowercased()
    }
}

/// The technical name of a component named by a constant.
let promoComponent = "promo-banner"

/// Content conformed by hand with `@StoryblokContent`, naming its component with an escaped
/// literal and with a constant, which must both mean what they say.
@StoryblokContent("landing\u{2D}page")
struct Landing : Decodable {
    let title: String
}

@StoryblokContent(promoComponent)
struct Promo : Decodable {
    let title: String
}

/// Content whose `CodingKeys` are private, escape a raw value and declare a case under `#if`, which
/// the field table must name as decoding does.
@StoryblokContent("article")
struct Renamed : Decodable {
    let title: String
    let summary: String

    private enum CodingKeys: String, CodingKey {
        case title = "hero\u{2D}title"
        #if swift(>=5)
        case summary = "teaser"
        #else
        case summary = "abstract"
        #endif
    }
}

/// A block library whose `CodingKeys` raw values use escapes, for its component's name and for a
/// relation field's key, which the macro must write out as the values they denote.
@BlockLibrary
indirect enum EscapedLibrary : Decodable {
    case landing(Landing)
    case unknown

    enum CodingKeys: String, CodingKey {
        case landing = "landing\u{2D}page"
        case unknown
    }

    struct Landing : Decodable {
        let author: Story<EscapedLibrary>?

        enum CodingKeys: String, CodingKey {
            case author = "main\u{2D}author"
        }
    }
}

@Suite
struct ExistingContentTests {

    @Test
    func `content holding a non-Sendable value can still be queried`() {
        #expect(MutableLibrary.Widget.technicalName == "widget")
        #expect(MutableLibrary.technicalName == nil)
    }

    @Test
    func `a technical name is the argument's value, however it is written`() {
        #expect(Landing.technicalName == "landing-page")
        #expect(Promo.technicalName == "promo-banner")
    }

    @Test
    func `a field is named as its CodingKeys case decodes it`() {
        #expect(Renamed.fieldNames[\Renamed.title] == "hero-title")
        #expect(Renamed.fieldNames[\Renamed.summary] == "teaser")
    }

    @Test
    func `escaped raw values name components and relations by their values`() throws {
        #expect(EscapedLibrary.relations == "landing-page.main-author")
        #expect(EscapedLibrary.Landing.technicalName == "landing-page")

        let content = try JSONDecoder().decode(EscapedLibrary.self, from: Data(#"{ "_uid": "a", "component": "landing-page" }"#.utf8))
        guard case .landing = content else {
            Issue.record("expected the landing-page component to decode as .landing, got \(content)")
            return
        }
    }

    @Test
    func `content with a lazy property can still be queried`() {
        #expect(LazyLibrary.Note.fieldNames.values.sorted() == ["title"])
    }
}
