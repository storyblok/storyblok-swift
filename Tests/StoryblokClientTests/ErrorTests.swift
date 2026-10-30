import Testing
import Foundation
import URLSessionExtension
@testable import StoryblokClient

@BlockLibrary
enum ErrorBlock {
    case page(Page)

    struct Page {
        let title: String
        let related: [Story<ErrorBlock.Page>]
    }
}

/// How `story()` and `stories()` classify a failure into the client's own error.
@Suite
struct ErrorTests {

    struct Library : BlockLibrary {}

    typealias Error = StoryblokClient<Library>.Error

    @Test
    func `a decoding failure stays a decoding failure`() {
        let failure = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "changed"))

        guard case .decoding = Error.from(failure) else {
            Issue.record("expected .decoding")
            return
        }
    }

    @Test
    func `an error response from the API carries its body as the message`() {
        let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)!
        let failure = Api.ResponseError.client(statusCode: 404, data: Data("not found".utf8), response: response)

        let error = Error.from(failure)

        guard case .api(message: "not found", underlyingError: _) = error else {
            Issue.record("expected .api with the response body, got \(error)")
            return
        }
    }

    @Test
    func `the client's own error passes through unchanged`() {
        let error = Error.from(Error.api(message: "already mapped", underlyingError: nil))

        #expect(error.message == "already mapped")
    }

    @Test
    func `any other failure is a failed request`() {
        guard case .api = Error.from(URLError(.notConnectedToInternet)) else {
            Issue.record("expected .api")
            return
        }
    }

    private let homeUuid = "11111111-1111-1111-1111-111111111111"

    /// The client's error for decoding a response whose story has `content`, with the story itself in `rels`.
    private func decodingError(_ content: String) -> StoryblokClient<ErrorBlock>.Error? {
        let story = """
        {"id": 1, "uuid": "\(homeUuid)", "name": "Home", "content": \(content), "slug": "home", "full_slug": "home",
         "created_at": "2025-07-09T14:35:26.851Z", "published_at": null, "first_published_at": null, "updated_at": null,
         "sort_by_date": null, "position": 0, "tag_list": [], "is_startpage": false, "parent_id": null, "meta_data": null,
         "group_id": "33333333-3333-3333-3333-333333333333", "release_id": null, "lang": "default", "path": null,
         "alternates": [], "default_full_slug": null, "translated_slugs": null}
        """
        do {
            _ = try StoryblokClient<ErrorBlock>.decoder(resolveLevel: 1)
                .decode(ContentResponse<Story<ErrorBlock>>.self, from: Data(#"{"story": \#(story), "rels": [\#(story)]}"#.utf8))
            return nil
        } catch {
            return .from(error)
        }
    }

    @Test
    func `a circular relation is described with where it was found`() throws {
        let error = try #require(decodingError(#"{"component": "page", "title": "Home", "related": ["\#(homeUuid)"]}"#))

        #expect(error.localizedDescription.hasPrefix("Invalid data at rels[0].content.related[0]: Circular story relation: \(homeUuid)"))
        #expect(error.message == error.localizedDescription)
    }

    @Test
    func `a missing field is described by its key and where it was expected`() throws {
        let error = try #require(decodingError(#"{"component": "page", "related": []}"#))

        #expect(error.localizedDescription.hasPrefix(#"Missing key "title" at story.content: "#))
    }

    @Test
    func `a value of the wrong type is described by the type expected and where`() throws {
        let error = try #require(decodingError(#"{"component": "page", "title": 5, "related": []}"#))

        #expect(error.localizedDescription.hasPrefix("Type mismatch for String at story.content.title: "))
    }

    @Test
    func `a decoding failure at the top level is described without a path`() {
        let error = Error.from(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "changed")))

        #expect(error.localizedDescription == "Invalid data: changed")
    }
}
