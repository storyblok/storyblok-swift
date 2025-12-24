import Foundation
import Testing

@Suite struct `MAPI: Releases` {

    /**
     * This endpoint allows you to create a new release.
     * https://www.storyblok.com/docs/api/management/releases/create-a-release
     */
    @Test
    func `Create a Release`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/releases/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
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
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a release using its numeric id.
     * https://www.storyblok.com/docs/api/management/releases/delete-a-release
     */
    @Test
    func `Delete a Release`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/releases/18")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single release object by providing a specific numeric ID.
     * https://www.storyblok.com/docs/api/management/releases/retrieve-a-single-release
     */
    @Test
    func `Retrieve a Single Release`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/releases/18")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of releases.
     * https://www.storyblok.com/docs/api/management/releases/retrieve-multiple-releases
     */
    @Test
    func `Retrieve Multiple Releases`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/releases/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows you to update a release using the numeric ID.
     * https://www.storyblok.com/docs/api/management/releases/update-a-release
     */
    @Test
    func `Update a Release`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/releases/123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
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
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}