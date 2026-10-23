import Testing
import Foundation
import Combine
import StoryblokClient

/// Uses of the 1.x API that must keep compiling. Each test passes by compiling.
@Suite
struct SourceCompatibilityTests {

    @Test
    func `story can still be referenced as a two-argument function`() {
        let client = StoryblokClient(library: Block.self, accessToken: "mock-api-key")
        let bySlug: (String, Int) -> AnyPublisher<Story<Block>, StoryblokClient<Block>.Error> = client.story
        let byUuid: (UUID, Int) -> AnyPublisher<Story<Block>, StoryblokClient<Block>.Error> = client.story

        _ = (bySlug, byUuid)
    }
}
