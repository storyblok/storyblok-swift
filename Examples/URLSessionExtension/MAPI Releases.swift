import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: Releases` {

    /**
     * This endpoint allows you to create a new release.
     * https://www.storyblok.com/docs/api/management/releases/create-a-release
     */
    @Test
    func `Create a Release`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/releases/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "release": [
                "branches_to_deploy": [
                    123,
                    456,
                ],
                "name": "Summer Special",
                "release_at": "2025-01-01 01:01",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a release using its numeric id.
     * https://www.storyblok.com/docs/api/management/releases/delete-a-release
     */
    @Test
    func `Delete a Release`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/releases/18")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single release object by providing a specific numeric ID.
     * https://www.storyblok.com/docs/api/management/releases/retrieve-a-single-release
     */
    @Test
    func `Retrieve a Single Release`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/releases/18")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of releases.
     * https://www.storyblok.com/docs/api/management/releases/retrieve-multiple-releases
     */
    @Test
    func `Retrieve Multiple Releases`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/releases/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows you to update a release using the numeric ID.
     * https://www.storyblok.com/docs/api/management/releases/update-a-release
     */
    @Test
    func `Update a Release`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/releases/123")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "do_release": true,
            "release": [
                "branches_to_deploy": [
                    123,
                    456,
                ],
                "name": "Summer Special",
                "release_at": "2025-01-01 01:01",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}