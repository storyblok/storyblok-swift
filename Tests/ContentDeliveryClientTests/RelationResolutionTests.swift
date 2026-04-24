import Foundation
import Testing
@testable import ContentDeliveryClient

@Suite struct RelationResolutionTests {

    indirect enum MyBlock : ContentDeliveryClient.Block {
        case author(Author)
        case article(Article)
        case popular(articles: [Story<Article>])
        
        struct Author : ContentDeliveryClient.Block {
            let name: String
        }

        struct Article : ContentDeliveryClient.Block {
            let headline: String
            let author: Story<Author>
                        
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.headline = try container.decode(String.self, forKey: .headline)
                let author = try container.decode(Story<MyBlock>.self, forKey: .author)
                if case .author(let content) = author.content {
                    self.author = Story(author, content: content)
                } else {
                    throw DecodingError.dataCorruptedError(forKey: .author, in: container, debugDescription: "Expected Story<Author> but got: \(author.content)")
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case headline
                case author
            }
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let component = try container.decode(String.self, forKey: .component)
            switch component {
            case "author":
                self = .author(try Author(from: decoder))
            case "article":
                self = .article(try Article(from: decoder))
            case "popular":
                let articles = try container.decode([Story<MyBlock>].self, forKey: .articles)
                self = .popular(articles: try articles.map {
                    if case .article(let content) = $0.content {
                        return Story($0, content: content)
                    }
                    throw DecodingError.dataCorruptedError(forKey: .author, in: container, debugDescription: "Expected Story<Article> but got: \($0.content)")
                })
            default:
                throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
            }
        }

        enum CodingKeys: String, CodingKey {
            case component
            case author
            case article
            case articles
            case popular
        }
    }

    private let authorUuid = "11111111-1111-1111-1111-111111111111"
    private let articleUuid = "22222222-2222-2222-2222-222222222222"
    private let otherUuid = "55555555-5555-5555-5555-555555555555"

    private func makeDecoder(relStore: RelationStore) -> JSONDecoder {
        let decoder = StoryblokClient(accessToken: "mock").decoder
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

