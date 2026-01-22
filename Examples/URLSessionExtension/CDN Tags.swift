import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `CDN: Tags` {

    /**
     * Retrieve tags used in a space.
     * https://www.storyblok.com/docs/api/content-delivery/v2/tags/retrieve-multiple-tags
     */
    @Test
    func `Retrieve Multiple Tags`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "ask9soUkv02QqbZgmZdeDAtt"))
        var request = URLRequest(storyblok: storyblok, path: "tags")
        request.url!.append(queryItems: [
            URLQueryItem(name: "starts_with", value: "articles/")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}
