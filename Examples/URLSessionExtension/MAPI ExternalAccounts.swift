import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: ExternalAccounts` {

    /**
     * Use this endpoint to obtain details of the GitHub account connected to Storyblok.
     * https://www.storyblok.com/docs/api/management/external-accounts/github
     */
    @Test
    func GitHub() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "v1/auth/github/me")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}