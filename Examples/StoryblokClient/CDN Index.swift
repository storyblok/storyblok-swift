import Combine
import Foundation
import Testing
import StoryblokClient

@Suite(.serialized) struct `CDN: Index` {

    /**
     * Learn the basics of the Storyblok Content Delivery API, including authentication, caching, CDN, pagination, rate limits, and error handling.
     * https://www.storyblok.com/docs/api/content-delivery/v2/index
     */
    @Test
    func `Introduction to the Content Delivery API`() async throws {
        let client = StoryblokClient(
            library: Block.self,
            accessToken: "ask9soUkv02QqbZgmZdeDAtt",
            version: .published,
            region: .eu
        )
        
        let stories: Page<Story<Block>>? = try await client
            .stories()
            .last()
            .values
            .first { @Sendable _ in true }
        
        print(stories!)
    }

}