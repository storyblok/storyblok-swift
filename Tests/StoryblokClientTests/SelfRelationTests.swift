import Foundation
import Testing
@testable import StoryblokClient

// Not `indirect`: a story keeps its content behind a reference, so a page can relate to a page, and a case can hold
// a story of the library, without one.
@BlockLibrary
enum SelfRelationBlock {
    case page(Page)
    case article(Article)
    case featured(article: Story<SelfRelationBlock>?)

    struct Page: Hashable, Sendable {
        let title: String
        let related: Story<Page>?
    }

    struct Article {
        let title: String
        let related: Story<Article>
    }
}

/// A content struct whose field relates it to a story of its own type, as a page's `related` page does.
@Suite
struct SelfRelationTests {

    private static let home = "11111111-1111-1111-1111-111111111111"

    /// A response for a story of `component` titled Home whose `field` is Home itself.
    private func relatedToItself(_ component: String, field: String = "related") -> Data {
        let story = """
            {"id": 1, "uuid": "\(Self.home)", "name": "Home",
             "content": {"component": "\(component)", "title": "Home", "\(field)": "\(Self.home)"},
             "slug": "home", "full_slug": "home", "created_at": "2025-07-09T14:35:26.851Z", "published_at": null,
             "first_published_at": null, "updated_at": null, "sort_by_date": null, "position": 0, "tag_list": [],
             "is_startpage": false, "parent_id": null, "meta_data": null,
             "group_id": "33333333-3333-3333-3333-333333333333", "release_id": null, "lang": "default", "path": null,
             "alternates": [], "default_full_slug": null, "translated_slugs": null}
            """
        return Data(#"{"story": \#(story), "rels": [\#(story)]}"#.utf8)
    }

    private func decode<Content>(_ data: Data, as content: Content.Type) throws -> Story<Content> {
        try StoryblokClient<SelfRelationBlock>.decoder(resolveLevel: 1)
            .decode(ContentResponse<Story<Content>>.self, from: data)
            .payload
    }

    @Test
    func `a story of the content's own type is a relation`() {
        #expect(SelfRelationBlock.relations == "article.related,featured.article,page.related")
    }

    @Test
    func `a case holding an optional story of the library resolves to the relation depth`() throws {
        let story = try decode(relatedToItself("featured", field: "article"), as: SelfRelationBlock.self)

        guard case let .featured(article?) = story.content, case let .featured(nested) = article.content else {
            Issue.record("expected a featured story holding a featured story, got \(story.content)")
            return
        }
        #expect(article.uuid == UUID(uuidString: Self.home))
        #expect(nested == nil)
    }

    @Test
    func `an optional story of the content's own type resolves to the relation depth`() throws {
        let story = try decode(relatedToItself("page"), as: SelfRelationBlock.Page.self)

        #expect(story.content.related?.content.title == "Home")
        #expect(story.content.related?.content.related == nil)
    }

    @Test
    func `a required story of the content's own type fails at the circular relation`() {
        #expect {
            try decode(relatedToItself("article"), as: SelfRelationBlock.Article.self)
        } throws: { error in
            guard case let DecodingError.dataCorrupted(context) = error else { return false }
            return context.debugDescription.hasPrefix("Circular story relation")
        }
    }

    @Test
    func `stories with equal content are equal and hash alike`() throws {
        let story = try decode(relatedToItself("page"), as: SelfRelationBlock.Page.self)
        let again = try decode(relatedToItself("page"), as: SelfRelationBlock.Page.self)

        #expect(story == again)
        #expect(Set([story, again]).count == 1)
    }
}
