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

@Suite
struct NonSendableContentTests {

    @Test
    func `content holding a non-Sendable value can still be queried`() {
        #expect(MutableLibrary.Widget.technicalName == "widget")
        #expect(MutableLibrary.technicalName == nil)
    }
}
