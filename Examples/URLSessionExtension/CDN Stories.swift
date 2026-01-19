import Foundation
import Testing
import URLSessionExtension

@Suite struct `CDN: Stories` {

    /**
     * Retrieve a single story by full slug, ID, or UUID using the Content Delivery API. Includes parameters for resolving links and relations.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/retrieve-a-single-story
     */
    @Test
    func `Retrieve a Single Story`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        let request = URLRequest(storyblok: storyblok, path: "stories/posts/my-third-post")
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Retrieve multiple stories from Storyblok using the Content Delivery API with filtering, pagination, sorting, and relation resolution options.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/retrieve-multiple-stories
     */
    @Test
    func `Retrieve Multiple Stories`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories")
        request.url!.append(queryItems: [
            URLQueryItem(name: "version", value: "published"),
            URLQueryItem(name: "starts_with", value: "articles")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Example showing how to retrieve a version of a story from a specific release by using the from_release query parameter.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-an-edited-version-of-a-story-from-a-release
     */
    @Test
    func `Retrieving a Story from a Specific Release`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "krcV6QGxWORpYLUWt12xKQtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/home")
        request.url!.append(queryItems: [
            URLQueryItem(name: "version", value: "draft"),
            URLQueryItem(name: "cv", value: "1765990908"),
            URLQueryItem(name: "from_release", value: "124105888551306")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Example showing how to retrieve localized story versions using UUID and language parameters in the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-localized-stories-by-uuid
     */
    @Test
    func `Retrieving Localized Stories by UUID`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "krcV6QGxWORpYLUWt12xKQtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/660452d2-1a68-4493-b5b6-2f03b6fa722b")
        request.url!.append(queryItems: [
            URLQueryItem(name: "find_by", value: "uuid"),
            URLQueryItem(name: "language", value: "de"),
            URLQueryItem(name: "version", value: "published")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Learn how to retrieve stories from specific folders using the starts_with parameter in Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-from-a-folder
     */
    @Test
    func `Retrieving Stories from a Folder`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories")
        request.url!.append(queryItems: [
            URLQueryItem(name: "starts_with", value: "articles/"),
            URLQueryItem(name: "version", value: "draft")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Example demonstrating how to retrieve translated story versions using the language parameter in Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-in-a-particular-language
     */
    @Test
    func `Retrieving Stories in a Particular Language`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "krcV6QGxWORpYLUWt12xKQtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/articles/earths-symphony-navigating-wonders-challenges-blue-oasis")
        request.url!.append(queryItems: [
            URLQueryItem(name: "language", value: "de"),
            URLQueryItem(name: "version", value: "published")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Learn how to resolve referenced stories using the resolve_relations parameter in Storyblok's Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-with-resolved-relations
     */
    @Test
    func `Retrieving Stories with Resolved Relations`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "krcV6QGxWORpYLUWt12xKQtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories")
        request.url!.append(queryItems: [
            URLQueryItem(name: "resolve_relations", value: "article.categories,article.author")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Example showing how to sort stories by custom fields defined in your story type schema using the sort_by parameter.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/sorting-by-fields-associated-with-a-story-type
     */
    @Test
    func `Sorting by Fields Associated with a Story Type`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "krcV6QGxWORpYLUWt12xKQtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "sort_by", value: "content.headline:asc")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Learn how to sort stories by default story properties like name, position, and publication dates using the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/sorting-by-story-object-property
     */
    @Test
    func `Sorting by Story Object Property`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "krcV6QGxWORpYLUWt12xKQtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories")
        request.url!.append(queryItems: [
            URLQueryItem(name: "sort_by", value: "first_published_at:desc")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}