import Foundation
import Logging
import Testing
import Mocker
@testable import StoryblokClient

@BlockLibrary
indirect enum Block : Decodable {
    case post(Post)
    case author(Author)
    case page(Page)
    case header(altTitle: String, altSubtitle: String, altImage: Field.Asset)
    case metadata
    case highlighted(title: String, post: Story<Post>)
    case recent(posts: [Story<Post>])
    case popular(title: String, posts: [Story<Post>])
    case recommended(strapline: String, posts: [Story<Post>])
    
    struct Page: Decodable {
        let title: String
        let body: [Block]
    }

    struct Post: Decodable {
        let title: String
        let subtitle: String?
        let url: Field.Link
        let image: Field.Asset
        let thumbnailImage: Field.Asset
        let body: RichText<Block>
        let date: Date
        let author: Story<Author>
        let readTimeMinutes: Int
    }

    struct Author: Decodable {
        let name: String
        let url: Field.Link?
    }

    enum HeaderCodingKeys: String, CodingKey {
        case altTitle = "alternativeTitle"
        case altSubtitle = "alternativeSubtitle"
        case altImage = "alternativeImage"
    }

}

@Suite struct StoryblokClientTests: TestTrait {
    
    static let ensureTraceLogging: () = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .trace
            return handler
        }
    }()
    
    @Suite(.serialized)
    class GetStory {
        
        let mockConfiguration = URLSessionConfiguration.default
        
        init() {
            ensureTraceLogging
            mockConfiguration.protocolClasses = [MockingURLProtocol.self]
        }
        
        deinit {
            Mocker.removeAll()
        }
        
        let data = """
        {
            "story": {
                "id": 42,
                "uuid": "11111111-1111-1111-1111-111111111111",
                "name": "Alice",
                "content": { "_uid": "a1", "component": "page", "title": "Home", "body": [] },
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

        @Test
        func `story request typed to root block library enum suceeds`() async throws {
            let mock = Mock(
                url: URL.init(string: "https://api.storyblok.com/v2/cdn/stories/mock-slug")!,
                ignoreQuery: true,
                cacheStoragePolicy: .allowedInMemoryOnly,
                contentType: .json,
                statusCode: 200,
                data: [.get: data]
            )
            mock.register()
            
            let client = StoryblokClient(
                library: Block.self,
                session: URLSession(storyblok: .cdn(accessToken: "mock-api-key", version: .draft, cv: "mock-cv"), configuration: mockConfiguration)
            )

            let story: Story<Block>? = try await client.story("mock-slug")
                .values
                .first { _ in true }
            
            if case let .page(page) = story?.content {
                #expect(page.title == "Home")
            } else {
                #expect(Bool(false))
            }


        }
        
        @Test
        func `story request typed to expected block library nested type suceeds`() async throws {
            let mock = Mock(
                url: URL.init(string: "https://api.storyblok.com/v2/cdn/stories/mock-slug")!,
                ignoreQuery: true,
                cacheStoragePolicy: .allowedInMemoryOnly,
                contentType: .json,
                statusCode: 200,
                data: [.get: data]
            )
            mock.register()
            
            let client = StoryblokClient(
                library: Block.self,
                session: URLSession(storyblok: .cdn(accessToken: "mock-api-key", version: .draft, cv: "mock-cv"), configuration: mockConfiguration)
            )

            let story: Story<Block.Page>? = try await client.story("mock-slug")
                .values
                .first { _ in true }

            #expect(story!.content.title == "Home")

        }
    }
}
