import Foundation
import Testing

@Suite struct `CDN: GettingStarted` {

    /**
     * Discover how Storyblok's API authentication mechanism works through API access tokens.
     * https://www.storyblok.com/docs/api/content-delivery/v2/getting-started/authentication
     */
    @Test
    func Authentication() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/stories?token=wANpEQEsMYGOwLxwXQ76Ggtt&version=published")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Explore how Storyblok optimizes content delivery through its Content Delivery Network (CDN) and cache versioning mechanism. Learn about the cv parameter.
     * https://www.storyblok.com/docs/api/content-delivery/v2/getting-started/cache-invalidation
     */
    @Test
    func `Cache Invalidation`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/spaces/me?token=wANpEQEsMYGOwLxwXQ76Ggtt")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

    /**
     * Explore how Storyblok optimizes content delivery through its Content Delivery Network (CDN) and cache versioning mechanism. Learn about the cv parameter.
     * https://www.storyblok.com/docs/api/content-delivery/v2/getting-started/cache-invalidation
     */
    @Test
    func `Cache Invalidation 2`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/stories?cv=1541863983&token=wANpEQEsMYGOwLxwXQ76Ggtt")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}