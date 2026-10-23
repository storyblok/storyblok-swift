import Testing
import Foundation
@testable import StoryblokClient

@Suite("StoryQuery")
struct StoryQueryTests {

    @Test
    func `an empty query states no parameters`() {
        #expect(StoryQuery().queryItems.isEmpty)
    }

    @Test
    func `each property maps to its parameter, and added parameters follow`() {
        var query = StoryQuery {
            $0.excludingFields = ["body", "seo"]
            $0.fromRelease = "12345"
        }
        query.parameter("future_param", "value")

        #expect(query.queryItems == [
            URLQueryItem(name: "excluding_fields", value: "body,seo"),
            URLQueryItem(name: "from_release", value: "12345"),
            URLQueryItem(name: "future_param", value: "value"),
        ])
    }
}
