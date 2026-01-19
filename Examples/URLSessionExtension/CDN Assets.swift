import Foundation
import Testing
import URLSessionExtension

@Suite struct `CDN: Assets` {

    /**
     * Retrieves a signed URL to access a private asset.
     * https://www.storyblok.com/docs/api/content-delivery/v2/assets/get-signed-url
     */
    @Test
    func `Get Signed URL`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "cNGPp8cvuCfoAZB3g3eHrAtt"))
        var request = URLRequest(storyblok: storyblok, path: "assets/me")
        request.url!.append(queryItems: [
            URLQueryItem(name: "filename", value: "https://a.storyblok.com/f/44203/x/5231aa9c8a/favicon.ico")
        ])
        let (data, response) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
        #expect((200...299).contains((response as! HTTPURLResponse).statusCode))
    }

}