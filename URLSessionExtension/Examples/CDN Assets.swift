import Foundation
import Testing

@Suite struct `CDN: Assets` {

    /**
     * Retrieves a signed URL to access a private asset.
     * https://www.storyblok.com/docs/api/content-delivery/v2/assets/get-signed-url
     */
    @Test
    func `Get Signed URL`() async throws {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "https://api.storyblok.com/v2/cdn/assets/me?token=cNGPp8cvuCfoAZB3g3eHrAtt&filename=https%3A%2F%2Fa.storyblok.com%2Ff%2F44203%2Fx%2F5231aa9c8a%2Ffavicon.ico")!)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}