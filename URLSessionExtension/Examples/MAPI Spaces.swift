import Foundation
import Testing

@Suite struct `MAPI: Spaces` {

    /**
     * Trigger the backup task for your space. Make sure you've configured backups in your space options.
     * https://www.storyblok.com/docs/api/management/spaces/backup-a-space
     */
    @Test
    func `Backup a Space`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/backups")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [ ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint creates a new space.
     * https://www.storyblok.com/docs/api/management/spaces/create-a-space
     */
    @Test
    func `Create a Space`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "space": [
                "name": "Example Space",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a space by its numeric id.
     * https://www.storyblok.com/docs/api/management/spaces/delete-a-space
     */
    @Test
    func `Delete a Space`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Duplicate a space and all its content entries and components; Assets will not be duplicated and still will reference the original space.
     * https://www.storyblok.com/docs/api/management/spaces/duplicate-a-space
     */
    @Test
    func `Duplicate a Space`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "dup_id": 12422,
            "space": [
                "name": "Example Space",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single space object by providing a specific numeric id.
     * https://www.storyblok.com/docs/api/management/spaces/retrieve-a-single-space
     */
    @Test
    func `Retrieve a Single Space`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of space objects.
     * https://www.storyblok.com/docs/api/management/spaces/retrieve-multiple-spaces
     */
    @Test
    func `Retrieve Multiple Spaces`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a space using the numeric ID. You can only able to update the properties mentioned here.
     * https://www.storyblok.com/docs/api/management/spaces/update-a-space
     */
    @Test
    func `Update a Space`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "space": [
                "id": 12422,
                "name": "Updated Example Space",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}