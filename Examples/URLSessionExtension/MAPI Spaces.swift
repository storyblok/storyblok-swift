import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: Spaces` {

    /**
     * Trigger the backup task for your space. Make sure you've configured backups in your space options.
     * https://www.storyblok.com/docs/api/management/spaces/backup-a-space
     */
    @Test
    func `Backup a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/backups")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [ ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint creates a new space.
     * https://www.storyblok.com/docs/api/management/spaces/create-a-space
     */
    @Test
    func `Create a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "space": [
                "name": "Example Space",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a space by its numeric id.
     * https://www.storyblok.com/docs/api/management/spaces/delete-a-space
     */
    @Test
    func `Delete a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Duplicate a space and all its content entries and components; Assets will not be duplicated and still will reference the original space.
     * https://www.storyblok.com/docs/api/management/spaces/duplicate-a-space
     */
    @Test
    func `Duplicate a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "dup_id": 12422,
            "space": [
                "name": "Example Space",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single space object by providing a specific numeric id.
     * https://www.storyblok.com/docs/api/management/spaces/retrieve-a-single-space
     */
    @Test
    func `Retrieve a Single Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of space objects.
     * https://www.storyblok.com/docs/api/management/spaces/retrieve-multiple-spaces
     */
    @Test
    func `Retrieve Multiple Spaces`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a space using the numeric ID. You can only able to update the properties mentioned here.
     * https://www.storyblok.com/docs/api/management/spaces/update-a-space
     */
    @Test
    func `Update a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "space": [
                "id": 12422,
                "name": "Updated Example Space",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}
