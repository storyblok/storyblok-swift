import Foundation
import Testing

@Suite struct `MAPI: ExternalAccounts` {

    /**
     * Use this endpoint to obtain details of the GitHub account connected to Storyblok.
     * https://www.storyblok.com/docs/api/management/external-accounts/github
     */
    @Test
    func GitHub() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/v1/auth/github/me")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}