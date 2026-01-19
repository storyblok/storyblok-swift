import Foundation
import Testing
import URLSessionExtension

@Suite struct `CDN: Links` {

    /**
     * Retrieve a concise representation of stories and folders using the links endpoint in the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/links/retrieve-multiple-links
     */
    @Test
    func `Retrieve Multiple Links`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "krcV6QGxWORpYLUWt12xKQtt"))
        var request = URLRequest(storyblok: storyblok, path: "links")
        request.url!.append(queryItems: [
            URLQueryItem(name: "version", value: "published"),
            URLQueryItem(name: "starts_with", value: "articles")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}