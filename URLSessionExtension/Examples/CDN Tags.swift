import Foundation
import Testing

@Suite struct `CDN: Tags` {

    /**
     * Retrieve tags used in a space.
     * https://www.storyblok.com/docs/api/content-delivery/v2/tags/retrieve-multiple-tags
     */
    @Test
    func `Retrieve Multiple Tags`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/tags?starts_with=articles%2F&token=ask9soUkv02QqbZgmZdeDAtt")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}