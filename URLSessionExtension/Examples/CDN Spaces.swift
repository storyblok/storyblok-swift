import Foundation
import Testing

@Suite struct `CDN: Spaces` {

    /**
     * Retrieve information about the current Storyblok space including cache version, domain, and language configuration using the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/spaces/retrieve-current-space
     */
    @Test
    func `Retrieve Current Space`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/spaces/me?token=ask9soUkv02QqbZgmZdeDAtt")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}