import Foundation
import Testing
@testable import StoryblokClient

@BlockLibrary
enum ElementsBlock {
    case page(Page)
    case list(articles: [Story<Page>?])
    case shelf(articles: [Story<Page>?]?)

    struct Page {
        let title: String
        let related: [Story<Page>?]
    }
}

/// A `[Story<T>?]` relation keeps the stories it can resolve, with `nil` in place of each one it cannot.
@Suite
struct OptionalStoryElementsTests {

    static let home = "11111111-1111-1111-1111-111111111111"
    static let other = "22222222-2222-2222-2222-222222222222"
    static let missing = "33333333-3333-3333-3333-333333333333"

    private func story(_ uuid: String, _ content: String) -> String {
        """
        {"id": 1, "uuid": "\(uuid)", "name": "Story", "content": \(content),
         "slug": "story", "full_slug": "story", "created_at": "2025-07-09T14:35:26.851Z", "published_at": null,
         "first_published_at": null, "updated_at": null, "sort_by_date": null, "position": 0, "tag_list": [],
         "is_startpage": false, "parent_id": null, "meta_data": null, "group_id": "44444444-4444-4444-4444-444444444444",
         "release_id": null, "lang": "default", "path": null, "alternates": [], "default_full_slug": null,
         "translated_slugs": null}
        """
    }

    private func page(_ uuid: String, title: String, related: [String]) -> String {
        let related = related.map { $0 == "null" ? $0 : "\"\($0)\"" }.joined(separator: ", ")
        return story(uuid, #"{"component": "page", "title": "\#(title)", "related": [\#(related)]}"#)
    }

    private func decode<Content: Decodable>(_ story: String, rels: [String]) throws -> Story<Content> {
        let json = #"{"story": \#(story), "rels": [\#(rels.joined(separator: ", "))]}"#
        return try StoryblokClient<ElementsBlock>.decoder(resolveLevel: 1)
            .decode(ContentResponse<Story<Content>>.self, from: Data(json.utf8))
            .payload
    }

    private func titles(_ stories: [Story<ElementsBlock.Page>?]) -> [String?] {
        stories.map { $0?.content.title }
    }

    @Test
    func `a list of optional stories is a relation`() {
        #expect(ElementsBlock.relations == "list.articles,page.related,shelf.articles")
    }

    @Test
    func `a story that closes a cycle decodes as nil in its place`() throws {
        let home = page(Self.home, title: "Home", related: [Self.other, Self.home])
        let other = page(Self.other, title: "Other", related: [])

        let result: Story<ElementsBlock.Page> = try decode(home, rels: [home, other])

        #expect(titles(result.content.related) == ["Other", "Home"])
        #expect(titles(result.content.related[1]!.content.related) == ["Other", nil])
    }

    @Test
    func `a story that is not resolved decodes as nil in its place`() throws {
        let home = page(Self.home, title: "Home", related: [Self.missing, Self.other])
        let other = page(Self.other, title: "Other", related: [])

        let result: Story<ElementsBlock.Page> = try decode(home, rels: [other])

        #expect(titles(result.content.related) == [nil, "Other"])
    }

    @Test
    func `a null story decodes as nil in its place`() throws {
        let home = page(Self.home, title: "Home", related: ["null", Self.other])
        let other = page(Self.other, title: "Other", related: [])

        let result: Story<ElementsBlock.Page> = try decode(home, rels: [other])

        #expect(titles(result.content.related) == [nil, "Other"])
    }

    @Test
    func `an empty list stays empty`() throws {
        let result: Story<ElementsBlock.Page> = try decode(page(Self.home, title: "Home", related: []), rels: [])

        #expect(result.content.related.isEmpty)
    }

    @Test
    func `a labeled list of optional stories keeps the ones it resolves`() throws {
        let list = story(Self.home, #"{"component": "list", "articles": ["\#(Self.other)", "\#(Self.missing)"]}"#)
        let other = page(Self.other, title: "Other", related: [])

        let result: Story<ElementsBlock> = try decode(list, rels: [other])

        guard case .list(let articles) = result.content else {
            Issue.record("expected .list, got \(result.content)")
            return
        }
        #expect(titles(articles) == ["Other", nil])
    }

    @Test(arguments: [
        (#""#, nil),
        (#", "articles": null"#, nil),
        (#", "articles": []"#, []),
        (#", "articles": ["\#(OptionalStoryElementsTests.other)", "\#(OptionalStoryElementsTests.missing)"]"#, ["Other", nil]),
    ] as [(String, [String?]?)])
    func `an optional list of optional stories is nil only when absent or null`(field: String, expected: [String?]?) throws {
        let shelf = story(Self.home, #"{"component": "shelf"\#(field)}"#)
        let other = page(Self.other, title: "Other", related: [])

        let result: Story<ElementsBlock> = try decode(shelf, rels: [other])

        guard case .shelf(let articles) = result.content else {
            Issue.record("expected .shelf, got \(result.content)")
            return
        }
        #expect(articles.map(titles) == expected)
    }

    @Test
    func `a resolved story that does not decode still fails`() {
        let home = page(Self.home, title: "Home", related: [Self.other])
        let other = story(Self.other, #"{"component": "page", "related": []}"#)

        #expect(throws: DecodingError.self) {
            let _: Story<ElementsBlock.Page> = try decode(home, rels: [other])
        }
    }
}
