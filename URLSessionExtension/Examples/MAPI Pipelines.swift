import Foundation
import Testing

@Suite struct `MAPI: Pipelines` {

    /**
     * This endpoint creates a new branch.
     * https://www.storyblok.com/docs/api/management/pipelines/create-a-branch
     */
    @Test
    func `Create a Branch`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/branches/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "branch": [
                "name": "A new branch",
                "position": 2,
                "source_id": 12332,
                "url": "https://new_domain.com",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a branch using its numeric ID.
     * https://www.storyblok.com/docs/api/management/pipelines/delete-a-branch
     */
    @Test
    func `Delete a Branch`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/branches/14")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single branch object by providing a specific numeric id.
     * https://www.storyblok.com/docs/api/management/pipelines/retrieve-a-single-branch
     */
    @Test
    func `Retrieve a Single Branch`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/branches/14")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of  branch objects
     * https://www.storyblok.com/docs/api/management/pipelines/retrieve-multiple-branches
     */
    @Test
    func `Retrieve Multiple Branches`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/branches/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint updates a branch using its numeric ID.
     * https://www.storyblok.com/docs/api/management/pipelines/update-a-branch
     */
    @Test
    func `Update a Branch`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/branches/14")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "branch": [
                "name": "Branche 123",
                "position": 7,
                "source_id": 12345,
                "url": "https://new_url.com/",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}