import Foundation
import SwiftUI
import Testing
import StoryblokClient
@testable import RichTextView

/// `ImageView` conforms to `View`, so it is `@MainActor` isolated. The suite runs on the main
/// actor to match.
@Suite @MainActor struct ImageAccessibilityTests {

    /// Stand-in block library; these images contain no embedded blocks.
    private struct NoBlocks: View, Decodable {
        var body: some View { EmptyView() }
    }

    /// `RichText.Image` is `Decodable` only, so build one the way the renderer receives it.
    /// A `nil` argument omits the key entirely, matching an absent field in the API response.
    private func makeImage(alt: String?, title: String?) throws -> RichText<NoBlocks>.Image {
        var attrs: [String: Any] = [
            "id": 1,
            "src": "https://a.storyblok.com/f/1/image.jpg"
        ]
        if let alt { attrs["alt"] = alt }
        if let title { attrs["title"] = title }

        let data = try JSONSerialization.data(withJSONObject: ["attrs": attrs])
        return try JSONDecoder().decode(RichText<NoBlocks>.Image.self, from: data)
    }

    private func description(alt: String?, title: String?) throws -> String? {
        try ImageView(image: makeImage(alt: alt, title: title)).description
    }

    @Test
    func `alt wins over title when both are present`() throws {
        #expect(try description(alt: "Charging station", title: "Entrance") == "Charging station")
    }

    @Test
    func `empty alt falls back to title`() throws {
        #expect(try description(alt: "", title: "Charging station entrance") == "Charging station entrance")
    }

    @Test
    func `whitespace-only alt falls back to title`() throws {
        #expect(try description(alt: "   \n", title: "Charging station entrance") == "Charging station entrance")
    }

    @Test
    func `surrounding whitespace is trimmed from alt`() throws {
        #expect(try description(alt: "  Charging station  ", title: "Entrance") == "Charging station")
    }

    @Test
    func `surrounding whitespace is trimmed from title`() throws {
        #expect(try description(alt: nil, title: "  Entrance  ") == "Entrance")
    }

    @Test
    func `absent alt and title yield no description`() throws {
        #expect(try description(alt: nil, title: nil) == nil)
    }

    @Test
    func `empty and whitespace-only alt and title yield no description`() throws {
        #expect(try description(alt: "", title: "  \t ") == nil)
    }
}
