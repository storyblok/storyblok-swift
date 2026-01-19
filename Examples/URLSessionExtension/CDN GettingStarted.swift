import Foundation
import Testing
import URLSessionExtension

@Suite struct `CDN: GettingStarted` {

    /**
     * Discover how Storyblok's API authentication mechanism works through API access tokens.
     * https://www.storyblok.com/docs/api/content-delivery/v2/getting-started/authentication
     */
    @Test
    func Authentication() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "wANpEQEsMYGOwLxwXQ76Ggtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories")
        request.url!.append(queryItems: [
            URLQueryItem(name: "version", value: "published")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Explore how Storyblok optimizes content delivery through its Content Delivery Network (CDN) and cache versioning mechanism. Learn about the cv parameter.
     * https://www.storyblok.com/docs/api/content-delivery/v2/getting-started/cache-invalidation
     */
    @Test
    func `Cache Invalidation`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "wANpEQEsMYGOwLxwXQ76Ggtt"))
        let request = URLRequest(storyblok: storyblok, path: "spaces/me")
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Explore how Storyblok optimizes content delivery through its Content Delivery Network (CDN) and cache versioning mechanism. Learn about the cv parameter.
     * https://www.storyblok.com/docs/api/content-delivery/v2/getting-started/cache-invalidation
     */
    @Test
    func `Cache Invalidation 2`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "wANpEQEsMYGOwLxwXQ76Ggtt"))
        var request = URLRequest(storyblok: storyblok, path: "stories")
        request.url!.append(queryItems: [
            URLQueryItem(name: "cv", value: "1541863983")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}