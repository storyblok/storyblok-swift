import Foundation
import Testing

@Suite struct `CDN: Links` {

    /**
     * Retrieve a concise representation of stories and folders using the links endpoint in the Content Delivery API.
     * https://www.storyblok.com/docs/api/content-delivery/v2/links/retrieve-multiple-links
     */
    @Test
    func `Retrieve Multiple Links`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/links?token=krcV6QGxWORpYLUWt12xKQtt&version=published&starts_with=articles")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}