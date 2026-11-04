import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: Strata` {

    /**
     * Returns a ranked list of stories whose content matches a search term by meaning.
     * https://www.storyblok.com/docs/api/management/strata/search
     */
    @Test
    func `Search Management API`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/strata/search")
        request.url!.append(queryItems: [
            URLQueryItem(name: "q", value: "how do I return an order"),
            URLQueryItem(name: "version", value: "published"),
            URLQueryItem(name: "limit", value: "5")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}