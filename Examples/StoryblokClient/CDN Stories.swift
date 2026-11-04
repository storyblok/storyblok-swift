import Combine
import Foundation
import Testing
import StoryblokClient

@Suite(.serialized) struct `CDN: Stories` {

    /**
     * Example showing how to retrieve a version of a story from a specific release by using the from_release query parameter.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-an-edited-version-of-a-story-from-a-release
     */
    @Test
    func `Retrieving a Story from a Specific Release`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .draft,
            region: .eu
        )
        
        let story: Story<Block>? = try await client
            .story("home") { @Sendable query in
                query.fromRelease = "230891299745176"
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(story!)
    }

    /**
     * Example showing how to retrieve localized story versions using UUID and language parameters in the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-localized-stories-by-uuid
     */
    @Test
    func `Retrieving Localized Stories by UUID`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu,
            language: "de-DE"
        )
        
        let story: Story<Block>? = try await client
            .story(UUID(uuidString: "bfea4895-8a19-4e82-ae1c-1c591dce3094")!)
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(story!)
    }

    /**
     * Learn how to retrieve stories from specific folders using the starts_with parameter in Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-from-a-folder
     */
    @Test
    func `Retrieving Stories from a Folder`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .draft,
            region: .eu
        )
        
        let stories: Page<Story<Block>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block>) in
                query.startsWith = "posts"
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Example demonstrating how to retrieve translated story versions using the language parameter in Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-in-a-particular-language
     */
    @Test
    func `Retrieving Stories in a Particular Language`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu,
            language: "de-DE"
        )
        
        let story: Story<Block>? = try await client
            .story("posts/my-first-post")
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(story!)
    }

    /**
     * Learn how to resolve referenced stories using the resolve_relations parameter in Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-with-resolved-relations
     */
    @Test
    func `Retrieving Stories with Resolved Relations`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let story: Story<Block>? = try await client
            .story("posts/my-first-post") { @Sendable query in
                query.parameter("resolve_relations", "post.categories,post.author")
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(story!)
    }

    /**
     * Example showing how to sort stories by custom fields defined in your story type schema using the sort_by parameter.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/sorting-by-fields-associated-with-a-story-type
     */
    @Test
    func `Sorting by Fields Associated with a Story Type`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block.Post>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block.Post>) in
                query.sort(by: \.topics)
                query.startsWith = "posts"
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

    /**
     * Learn how to sort stories by default story properties like name, position, and publication dates using the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/sorting-by-story-object-property
     */
    @Test
    func `Sorting by Story Object Property`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block>>? = try await client
            .stories { @Sendable (query: inout StoriesQuery<Block>) in
                query.sort(by: .firstPublishedAt, .descending)
                query.startsWith = "authors"
            }
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

}