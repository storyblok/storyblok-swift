import Foundation
import Testing
@testable import ContentDeliveryClient

@Suite struct RelationResolutionTests {

    indirect enum MyBlock : Decodable, Hashable, ContentDeliveryClient.BlockLibrary {
        case author(Author)
        case article(Article)
        case popular(articles: [Story<Article>])

        struct Author : Decodable, Hashable {
            let name: String
        }

        struct Article : Decodable, Hashable {
            let headline: String
            let author: Story<Author>
        }

        static let relations: String = "article.author,popular.articles"

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let component = try container.decode(String.self, forKey: .component)
            switch component {
            case "author":
                self = .author(try Author(from: decoder))
            case "article":
                self = .article(try Article(from: decoder))
            case "popular":
                self = .popular(articles: try container.decode([Story<Article>].self, forKey: .articles))
            default:
                throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
            }
        }

        enum CodingKeys: String, CodingKey {
            case component
            case articles
        }
    }

    private let authorUuid = "11111111-1111-1111-1111-111111111111"
    private let articleUuid = "22222222-2222-2222-2222-222222222222"
    private let otherUuid = "55555555-5555-5555-5555-555555555555"

    private func makeDecoder(relStore: RelationStore) -> JSONDecoder {
        let decoder = StoryblokClient<MyBlock>(library: MyBlock.self, accessToken: "mock").decoder
        decoder.userInfo[.storyblokRelations] = relStore
        return decoder
    }

    private func wrapStory(content: String, extraStories: String = "", uuid: String? = nil) -> Data {
        let uuidValue = uuid ?? articleUuid
        return """
        {
            "story": {
                "id": 1,
                "uuid": "\(uuidValue)",
                "name": "Hello",
                "content": \(content),
                "slug": "hello",
                "full_slug": "articles/hello",
                "created_at": "2025-07-09T14:35:26.851Z",
                "published_at": null,
                "first_published_at": null,
                "updated_at": null,
                "sort_by_date": null,
                "position": 0,
                "tag_list": [],
                "is_startpage": false,
                "parent_id": null,
                "meta_data": null,
                "group_id": "33333333-3333-3333-3333-333333333333",
                "release_id": null,
                "lang": "default",
                "path": null,
                "alternates": [],
                "default_full_slug": null,
                "translated_slugs": null
            },
            "rels": [
                {
                    "id": 42,
                    "uuid": "\(authorUuid)",
                    "name": "Alice",
                    "content": { "_uid": "a1", "component": "author", "name": "Alice" },
                    "slug": "alice",
                    "full_slug": "authors/alice",
                    "created_at": "2025-07-09T14:35:26.851Z",
                    "published_at": null,
                    "first_published_at": null,
                    "updated_at": null,
                    "sort_by_date": null,
                    "position": 0,
                    "tag_list": [],
                    "is_startpage": false,
                    "parent_id": null,
                    "meta_data": null,
                    "group_id": "44444444-4444-4444-4444-444444444444",
                    "release_id": null,
                    "lang": "default",
                    "path": null,
                    "alternates": [],
                    "default_full_slug": null,
                    "translated_slugs": null
                }\(extraStories)
            ]
        }
        """.data(using: .utf8)!
    }

    @Test
    func `relation UUID is resolved into the referenced story during decoding`() throws {
        let data = wrapStory(content: """
            { "_uid": "c1", "component": "article", "headline": "Hi", "author": "\(authorUuid)" }
        """)
        
        let store = RelationStore()
        let decoder = makeDecoder(relStore: store)

        let response = try decoder.decode(StoryResponse<MyBlock>.self, from: data)

        if case let .article(article) = response.story.content {
            #expect(article.headline == "Hi")
            #expect(article.author.name == "Alice")
        } else {
            #expect(Bool(false), "Expected article")
        }
    }

    @Test
    func `missing relation UUID throws during decoding`() throws {
        let data = wrapStory(content: """
            { "_uid": "c1", "component": "article", "headline": "Hi", "author": "\(otherUuid)" }
        """)
        
        let store = RelationStore()
        let decoder = makeDecoder(relStore: store)

        #expect(throws: (any Error).self) {
            _ = try decoder.decode(StoryResponse<MyBlock>.self, from: data)
        }
    }

    @Test
    func `list of relation UUIDs is resolved into the referenced stories during decoding`() throws {
        let data = wrapStory(content: """
            { "_uid": "p1", "component": "popular", "articles": ["\(articleUuid)"] }
        """, extraStories: """
             , {
                "id": 1,
                "uuid": "\(articleUuid)",
                "name": "Hello",
                "content": { "_uid": "c1", "component": "article", "headline": "Hi", "author": "\(authorUuid)" },
                "slug": "hello",
                "full_slug": "articles/hello",
                "created_at": "2025-07-09T14:35:26.851Z",
                "published_at": null,
                "first_published_at": null,
                "updated_at": null,
                "sort_by_date": null,
                "position": 0,
                "tag_list": [],
                "is_startpage": false,
                "parent_id": null,
                "meta_data": null,
                "group_id": "33333333-3333-3333-3333-333333333333",
                "release_id": null,
                "lang": "default",
                "path": null,
                "alternates": [],
                "default_full_slug": null,
                "translated_slugs": null
            }
            """)

        let store = RelationStore()
        let decoder = makeDecoder(relStore: store)
        
        let response = try decoder.decode(StoryResponse<MyBlock>.self, from: data)
        
        if case let .popular(articles) = response.story.content {
            #expect(articles.count == 1)
            #expect(articles[0].content.headline == "Hi")
            #expect(articles[0].content.author.name == "Alice")
        } else {
            #expect(Bool(false), "Expected popular")
        }

    }

    // MARK: - Circular relation tests

    /// A minimal block type whose `ref` field can point to another `CircularBlock` story,
    /// enabling direct and indirect circular relation graphs.
    indirect enum CircularBlock: Decodable {
        case node(name: String, ref: Story<CircularBlock>?)

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name = try container.decode(String.self, forKey: .name)
            let ref = try container.decodeIfPresent(Story<CircularBlock>.self, forKey: .ref)
            self = .node(name: name, ref: ref)
        }

        enum CodingKeys: String, CodingKey { case name, ref }
    }

    private let nodeAUuid = "a0000000-0000-0000-0000-000000000000"
    private let nodeBUuid = "b0000000-0000-0000-0000-000000000000"
    private let nodeCUuid = "c0000000-0000-0000-0000-000000000000"

    private func makeRelJSON(uuid: String, name: String, ref: String?) -> String {
        let refValue = ref.map { "\"\($0)\"" } ?? "null"
        return """
        {
            "id": 1, "uuid": "\(uuid)", "name": "\(name)",
            "content": { "name": "\(name)", "ref": \(refValue) },
            "slug": "\(name.lowercased())", "full_slug": "nodes/\(name.lowercased())",
            "created_at": "2025-01-01T00:00:00.000Z",
            "published_at": null, "first_published_at": null, "updated_at": null,
            "sort_by_date": null, "position": 0, "tag_list": [], "is_startpage": false,
            "parent_id": null, "meta_data": null,
            "group_id": "00000000-0000-0000-0000-000000000000",
            "release_id": null, "lang": "default", "path": null, "alternates": [],
            "default_full_slug": null, "translated_slugs": null
        }
        """
    }

    @Test
    func `direct circular relation on optional field breaks cycle with nil`() throws {
        let data = """
        {
            "story": \(makeRelJSON(uuid: nodeAUuid, name: "A", ref: nodeBUuid)),
            "rels": [
                \(makeRelJSON(uuid: nodeAUuid, name: "A", ref: nodeBUuid)),
                \(makeRelJSON(uuid: nodeBUuid, name: "B", ref: nodeAUuid))
            ]
        }
        """.data(using: .utf8)!

        let store = RelationStore()
        let decoder = makeDecoder(relStore: store)
        let response = try decoder.decode(StoryResponse<CircularBlock>.self, from: data)

        // A → B → A (cycle break) → ref is nil
        guard case .node(let nameA, let refB) = response.story.content else { return #expect(Bool(false)) }
        guard case .node(let nameB, let refA) = refB?.content else { return #expect(Bool(false)) }
        guard case .node(_, let cyclicRef) = refA?.content else { return #expect(Bool(false)) }
        #expect(nameA == "A")
        #expect(nameB == "B")
        #expect(cyclicRef == nil)
    }

    @Test
    func `indirect circular relation via three stories breaks cycle with nil`() throws {
        let data = """
        {
            "story": \(makeRelJSON(uuid: nodeAUuid, name: "A", ref: nodeBUuid)),
            "rels": [
                \(makeRelJSON(uuid: nodeAUuid, name: "A", ref: nodeBUuid)),
                \(makeRelJSON(uuid: nodeBUuid, name: "B", ref: nodeCUuid)),
                \(makeRelJSON(uuid: nodeCUuid, name: "C", ref: nodeAUuid))
            ]
        }
        """.data(using: .utf8)!

        let store = RelationStore()
        let decoder = makeDecoder(relStore: store)
        let response = try decoder.decode(StoryResponse<CircularBlock>.self, from: data)

        // A → B → C → A → B (cycle break) → ref is nil
        guard case .node(let nameA, let refB) = response.story.content else { return #expect(Bool(false)) }
        guard case .node(let nameB, let refC) = refB?.content else { return #expect(Bool(false)) }
        guard case .node(let nameC, let refA) = refC?.content else { return #expect(Bool(false)) }
        guard case .node(_, let cyclicRef) = refA?.content else { return #expect(Bool(false)) }
        #expect(nameA == "A")
        #expect(nameB == "B")
        #expect(nameC == "C")
        #expect(cyclicRef == nil)
    }

    indirect enum NonOptionalCircularBlock: Decodable {
        case node(name: String, ref: Story<NonOptionalCircularBlock>)

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name = try container.decode(String.self, forKey: .name)
            let ref = try container.decode(Story<NonOptionalCircularBlock>.self, forKey: .ref)
            self = .node(name: name, ref: ref)
        }

        enum CodingKeys: String, CodingKey { case name, ref }
    }

    @Test
    func `direct circular relation on non-optional field throws during decoding`() throws {
        let data = """
        {
            "story": \(makeRelJSON(uuid: nodeAUuid, name: "A", ref: nodeBUuid)),
            "rels": [
                \(makeRelJSON(uuid: nodeAUuid, name: "A", ref: nodeBUuid)),
                \(makeRelJSON(uuid: nodeBUuid, name: "B", ref: nodeAUuid))
            ]
        }
        """.data(using: .utf8)!

        let store = RelationStore()
        let decoder = makeDecoder(relStore: store)

        #expect {
            _ = try decoder.decode(StoryResponse<NonOptionalCircularBlock>.self, from: data)
        } throws: { error in
            guard case DecodingError.dataCorrupted(let context) = error else { return false }
            return context.debugDescription.hasPrefix("Circular story relation:")
        }
    }

    private struct ArticleWithOptionalAuthor: Decodable {
        let headline: String
        let author: Story<MyBlock.Author>?
    }

    private func makePlainDecoder() -> JSONDecoder {
        StoryblokClient<MyBlock>(library: MyBlock.self, accessToken: "mock").decoder
    }

    @Test
    func `optional story field decodes as nil when no relation store is present`() throws {
        let data = """
        {
            "story": {
                "id": 2, "uuid": "\(articleUuid)", "name": "Article",
                "content": { "headline": "Hello", "author": "\(authorUuid)" },
                "slug": "article", "full_slug": "articles/article",
                "created_at": "2025-01-01T00:00:00.000Z",
                "published_at": null, "first_published_at": null, "updated_at": null,
                "sort_by_date": null, "position": 0, "tag_list": [], "is_startpage": false,
                "parent_id": null, "meta_data": null,
                "group_id": "00000000-0000-0000-0000-000000000000",
                "release_id": null, "lang": "default", "path": null, "alternates": [],
                "default_full_slug": null, "translated_slugs": null
            }
        }
        """.data(using: .utf8)!

        let decoder = makePlainDecoder()
        let response = try decoder.decode(StoryResponse<ArticleWithOptionalAuthor>.self, from: data)
        #expect(response.story.content.author == nil)
    }

    @Test
    func `optional story field resolves when relation store is present`() throws {
        let data = """
        {
            "story": {
                "id": 2, "uuid": "\(articleUuid)", "name": "Article",
                "content": { "headline": "Hello", "author": "\(authorUuid)" },
                "slug": "article", "full_slug": "articles/article",
                "created_at": "2025-01-01T00:00:00.000Z",
                "published_at": null, "first_published_at": null, "updated_at": null,
                "sort_by_date": null, "position": 0, "tag_list": [], "is_startpage": false,
                "parent_id": null, "meta_data": null,
                "group_id": "00000000-0000-0000-0000-000000000000",
                "release_id": null, "lang": "default", "path": null, "alternates": [],
                "default_full_slug": null, "translated_slugs": null
            },
            "rels": [
                {
                    "id": 1, "uuid": "\(authorUuid)", "name": "Alice",
                    "content": { "name": "Alice" },
                    "slug": "alice", "full_slug": "authors/alice",
                    "created_at": "2025-01-01T00:00:00.000Z",
                    "published_at": null, "first_published_at": null, "updated_at": null,
                    "sort_by_date": null, "position": 0, "tag_list": [], "is_startpage": false,
                    "parent_id": null, "meta_data": null,
                    "group_id": "00000000-0000-0000-0000-000000000000",
                    "release_id": null, "lang": "default", "path": null, "alternates": [],
                    "default_full_slug": null, "translated_slugs": null
                }
            ]
        }
        """.data(using: .utf8)!

        let store = RelationStore()
        let decoder = makeDecoder(relStore: store)
        let response = try decoder.decode(StoryResponse<ArticleWithOptionalAuthor>.self, from: data)
        #expect(response.story.content.author?.content.name == "Alice")
    }

    private struct ArticleWithOptionalAuthorArray: Decodable {
        let headline: String
        let authors: [Story<MyBlock.Author>]?
    }

    @Test
    func `optional story array field decodes as nil when no relation store is present`() throws {
        let data = """
        {
            "story": {
                "id": 2, "uuid": "\(articleUuid)", "name": "Article",
                "content": { "headline": "Hello", "authors": ["\(authorUuid)", "\(otherUuid)"] },
                "slug": "article", "full_slug": "articles/article",
                "created_at": "2025-01-01T00:00:00.000Z",
                "published_at": null, "first_published_at": null, "updated_at": null,
                "sort_by_date": null, "position": 0, "tag_list": [], "is_startpage": false,
                "parent_id": null, "meta_data": null,
                "group_id": "00000000-0000-0000-0000-000000000000",
                "release_id": null, "lang": "default", "path": null, "alternates": [],
                "default_full_slug": null, "translated_slugs": null
            }
        }
        """.data(using: .utf8)!

        let decoder = makePlainDecoder()
        let response = try decoder.decode(StoryResponse<ArticleWithOptionalAuthorArray>.self, from: data)
        #expect(response.story.content.authors == nil)
    }

    @Test
    func `optional story array field resolves when relation store is present`() throws {
        let data = """
        {
            "story": {
                "id": 2, "uuid": "\(articleUuid)", "name": "Article",
                "content": { "headline": "Hello", "authors": ["\(authorUuid)"] },
                "slug": "article", "full_slug": "articles/article",
                "created_at": "2025-01-01T00:00:00.000Z",
                "published_at": null, "first_published_at": null, "updated_at": null,
                "sort_by_date": null, "position": 0, "tag_list": [], "is_startpage": false,
                "parent_id": null, "meta_data": null,
                "group_id": "00000000-0000-0000-0000-000000000000",
                "release_id": null, "lang": "default", "path": null, "alternates": [],
                "default_full_slug": null, "translated_slugs": null
            },
            "rels": [
                {
                    "id": 1, "uuid": "\(authorUuid)", "name": "Alice",
                    "content": { "name": "Alice" },
                    "slug": "alice", "full_slug": "authors/alice",
                    "created_at": "2025-01-01T00:00:00.000Z",
                    "published_at": null, "first_published_at": null, "updated_at": null,
                    "sort_by_date": null, "position": 0, "tag_list": [], "is_startpage": false,
                    "parent_id": null, "meta_data": null,
                    "group_id": "00000000-0000-0000-0000-000000000000",
                    "release_id": null, "lang": "default", "path": null, "alternates": [],
                    "default_full_slug": null, "translated_slugs": null
                }
            ]
        }
        """.data(using: .utf8)!

        let store = RelationStore()
        let decoder = makeDecoder(relStore: store)
        let response = try decoder.decode(StoryResponse<ArticleWithOptionalAuthorArray>.self, from: data)
        #expect(response.story.content.authors?.first?.content.name == "Alice")
    }

    @Test
    func `story without rels decodes normally`() throws {
        let data = """
        {
            "story": {
                "id": 42,
                "uuid": "\(authorUuid)",
                "name": "Alice",
                "content": { "_uid": "a1", "component": "author", "name": "Alice" },
                "slug": "alice",
                "full_slug": "authors/alice",
                "created_at": "2025-07-09T14:35:26.851Z",
                "published_at": null,
                "first_published_at": null,
                "updated_at": null,
                "sort_by_date": null,
                "position": 0,
                "tag_list": [],
                "is_startpage": false,
                "parent_id": null,
                "meta_data": null,
                "group_id": "44444444-4444-4444-4444-444444444444",
                "release_id": null,
                "lang": "default",
                "path": null,
                "alternates": [],
                "default_full_slug": null,
                "translated_slugs": null
            }
        }
        """.data(using: .utf8)!

        let store = RelationStore()
        let decoder = makeDecoder(relStore: store)
        let response = try decoder.decode(StoryResponse<MyBlock>.self, from: data)

        if case let .author(author) = response.story.content {
            #expect(author.name == "Alice")
        } else {
            #expect(Bool(false), "Expected author")
        }

    }
}


