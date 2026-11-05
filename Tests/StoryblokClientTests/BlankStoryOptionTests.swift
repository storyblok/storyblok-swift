import Foundation
import Testing
@testable import StoryblokClient

@BlockLibrary
enum CatalogBlock: Decodable {
    case category(Category)
    case product(Product)
    case promo(title: String, category: Story<Category>?)
    case feature(category: Story<Category>)
    case collection(Collection)
    case spotlight(collection: Story<Collection>?)
    case shelf(collections: [Story<Collection>]?)

    struct Category: Decodable {
        let name: String
    }

    struct Product: Decodable {
        let name: String
        let category: Story<Category>?
    }

    struct Collection: Decodable {
        let name: String
        let lead: Story<Category>
    }
}

@Suite struct BlankStoryOptionTests {

    private let categoryUuid = "11111111-1111-1111-1111-111111111111"
    private let collectionUuid = "44444444-4444-4444-4444-444444444444"

    private func storyJSON(id: Int, uuid: String, content: String) -> String {
        """
        {
            "id": \(id), "uuid": "\(uuid)", "name": "S\(id)", "content": \(content),
            "slug": "s\(id)", "full_slug": "s\(id)", "created_at": "2025-07-09T14:35:26.851Z",
            "published_at": null, "first_published_at": null, "updated_at": null, "sort_by_date": null,
            "position": 0, "tag_list": [], "is_startpage": false, "parent_id": null, "meta_data": null,
            "group_id": "33333333-3333-3333-3333-333333333333", "release_id": null, "lang": "default",
            "path": null, "alternates": [], "default_full_slug": null, "translated_slugs": null
        }
        """
    }

    /// Decodes `content` as a story's content. `rels` holds the category story, and a collection story whose required
    /// `lead` is the JSON `collectionLead`.
    private func decode(_ content: String, collectionLead: String? = nil) throws -> CatalogBlock {
        let category = storyJSON(id: 2, uuid: categoryUuid, content: #"{"component": "category", "name": "Shoes"}"#)
        let lead = collectionLead ?? #""\#(categoryUuid)""#
        let collection = storyJSON(id: 3, uuid: collectionUuid, content: #"{"component": "collection", "name": "Autumn", "lead": \#(lead)}"#)
        let json = """
        {"story": \(storyJSON(id: 1, uuid: "22222222-2222-2222-2222-222222222222", content: content)), "rels": [\(category), \(collection)]}
        """
        return try StoryblokClient<CatalogBlock>.makeDecoder(relStore: RelationStore())
            .decode(ContentResponse<Story<CatalogBlock>>.self, from: Data(json.utf8)).payload.content
    }

    @Test
    func `A blank optional story option in a struct decodes as nil`() throws {
        guard case .product(let product) = try decode(#"{"component": "product", "name": "Boot", "category": ""}"#) else {
            Issue.record("Expected .product"); return
        }
        #expect(product.name == "Boot")
        #expect(product.category == nil)
    }

    @Test
    func `A blank optional story option in a case value decodes as nil`() throws {
        guard case .promo(let title, let category) = try decode(#"{"component": "promo", "title": "Sale", "category": ""}"#) else {
            Issue.record("Expected .promo"); return
        }
        #expect(title == "Sale")
        #expect(category == nil)
    }

    @Test
    func `A selected story option still resolves`() throws {
        guard case .promo(_, let category) = try decode(#"{"component": "promo", "title": "Sale", "category": "\#(categoryUuid)"}"#) else {
            Issue.record("Expected .promo"); return
        }
        #expect(category?.content.name == "Shoes")
    }

    @Test
    func `A blank required story option throws`() {
        #expect(throws: DecodingError.self) {
            try decode(#"{"component": "feature", "category": ""}"#)
        }
    }

    @Test
    func `A story option that is not a UUID still throws`() {
        #expect(throws: DecodingError.self) {
            try decode(#"{"component": "promo", "title": "Sale", "category": "shoes"}"#)
        }
    }

    @Test
    func `A blank required story inside an optional related story throws`() throws {
        let content = #"{"component": "spotlight", "collection": "\#(collectionUuid)"}"#
        guard case .spotlight(let collection) = try decode(content) else {
            Issue.record("Expected .spotlight"); return
        }
        #expect(collection?.content.lead.content.name == "Shoes")
        #expect(throws: DecodingError.self) { try decode(content, collectionLead: #""""#) }
    }

    @Test
    func `A blank required story inside an optional list of related stories throws`() throws {
        let content = #"{"component": "shelf", "collections": ["\#(collectionUuid)"]}"#
        guard case .shelf(let collections) = try decode(content) else {
            Issue.record("Expected .shelf"); return
        }
        #expect(collections?.first?.content.lead.content.name == "Shoes")
        #expect(throws: DecodingError.self) { try decode(content, collectionLead: #""""#) }
    }
}
