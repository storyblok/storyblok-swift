import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `CDN: Spaces` {

    /**
     * Retrieve information about the current Storyblok space including cache version, domain, and language configuration using the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/spaces/retrieve-current-space
     */
    @Test
    func `Retrieve Current Space`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        let request = URLRequest(storyblok: storyblok, path: "spaces/me")
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}
