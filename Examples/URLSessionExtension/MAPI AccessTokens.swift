import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: AccessTokens` {

    /**
     * Create an access token for a particular space.
     * https://www.storyblok.com/docs/api/management/access-tokens/create-an-access-token
     */
    @Test
    func `Create an Access Token`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/api_keys/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "api_key": [
                "access": "public",
                "name": "My public Access token",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete an access token using its numeric ID.
     * https://www.storyblok.com/docs/api/management/access-tokens/delete-an-access-token
     */
    @Test
    func `Delete an Access Token`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/api_keys/2345")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of access token objects. The response of this endpoint is not paginated and you will retrieve all tokens.
     * https://www.storyblok.com/docs/api/management/access-tokens/retrieve-multiple-access-tokens
     */
    @Test
    func `Retrieve Multiple Access Tokens`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/api_keys/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update an access token with the numeric ID.
     * https://www.storyblok.com/docs/api/management/access-tokens/update-an-access-token
     */
    @Test
    func `Update an Access Token`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/api_keys/123123")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "api_key": [
                "access": "private",
                "name": "My updated token",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}