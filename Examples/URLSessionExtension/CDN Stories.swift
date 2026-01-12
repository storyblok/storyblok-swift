import Foundation
import Testing

@Suite struct `CDN: Stories` {

    /**
     * Retrieve a single story by full slug, ID, or UUID using the Content Delivery API. Includes parameters for resolving links and relations.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/retrieve-a-single-story
     */
    @Test
    func `Retrieve a Single Story`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/stories/posts/my-third-post?token=ask9soUkv02QqbZgmZdeDAtt")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Retrieve multiple stories from Storyblok using the Content Delivery API with filtering, pagination, sorting, and relation resolution options.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/retrieve-multiple-stories
     */
    @Test
    func `Retrieve Multiple Stories`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/stories?token=ask9soUkv02QqbZgmZdeDAtt&version=published&starts_with=articles")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Example showing how to retrieve localized story versions using UUID and language parameters in the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-localized-stories-by-uuid
     */
    @Test
    func `Retrieving Localized Stories by UUID`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/stories/660452d2-1a68-4493-b5b6-2f03b6fa722b?find_by=uuid&language=de&token=krcV6QGxWORpYLUWt12xKQtt&version=published")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Learn how to retrieve stories from specific folders using the starts_with parameter in Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-from-a-folder
     */
    @Test
    func `Retrieving Stories from a Folder`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/stories?starts_with=articles%2F&version=draft&token=ask9soUkv02QqbZgmZdeDAtt")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Example demonstrating how to retrieve translated story versions using the language parameter in Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-in-a-particular-language
     */
    @Test
    func `Retrieving Stories in a Particular Language`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/stories/articles/earths-symphony-navigating-wonders-challenges-blue-oasis?language=de&token=krcV6QGxWORpYLUWt12xKQtt&version=published")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Learn how to resolve referenced stories using the resolve_relations parameter in Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-with-resolved-relations
     */
    @Test
    func `Retrieving Stories with Resolved Relations`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/stories?resolve_relations=article.categories%2Carticle.author&token=krcV6QGxWORpYLUWt12xKQtt")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Example showing how to sort stories by custom fields defined in your story type schema using the sort_by parameter.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/sorting-by-fields-associated-with-a-story-type
     */
    @Test
    func `Sorting by Fields Associated with a Story Type`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/stories/?token=krcV6QGxWORpYLUWt12xKQtt&sort_by=content.headline%3Aasc")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Learn how to sort stories by default story properties like name, position, and publication dates using the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/sorting-by-story-object-property
     */
    @Test
    func `Sorting by Story Object Property`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/stories?token=krcV6QGxWORpYLUWt12xKQtt&sort_by=first_published_at%3Adesc")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}