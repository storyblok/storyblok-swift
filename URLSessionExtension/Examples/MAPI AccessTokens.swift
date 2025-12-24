import Foundation
import Testing

@Suite struct `MAPI: AccessTokens` {

    /**
     * Create an access token for a particular space.
     * https://www.storyblok.com/docs/api/management/access-tokens/create-an-access-token
     */
    @Test
    func `Create an Access Token`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/api_keys/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "api_key": [
                "access": "public",
                "name": "My public Access token",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete an access token using its numeric ID.
     * https://www.storyblok.com/docs/api/management/access-tokens/delete-an-access-token
     */
    @Test
    func `Delete an Access Token`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/api_keys/2345")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of access token objects. The response of this endpoint is not paginated and you will retrieve all tokens.
     * https://www.storyblok.com/docs/api/management/access-tokens/retrieve-multiple-access-tokens
     */
    @Test
    func `Retrieve Multiple Access Tokens`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/api_keys/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update an access token with the numeric ID.
     * https://www.storyblok.com/docs/api/management/access-tokens/update-an-access-token
     */
    @Test
    func `Update an Access Token`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/api_keys/123123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "api_key": [
                "access": "private",
                "name": "My updated token",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}