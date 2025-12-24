import Foundation
import Testing

@Suite struct `MAPI: InternalTags` {

    /**
     * This endpoint allows creating an internal tag inside a particular space.
     * https://www.storyblok.com/docs/api/management/internal-tags/create-an-internal-tag
     */
    @Test
    func `Create an Internal Tag`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/internal_tags")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "internal_tag": [
                "name": "New Release",
                "object_type": "component",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows deleting an internal tag using the numeric ID.
     * https://www.storyblok.com/docs/api/management/internal-tags/delete-an-internal-tag
     */
    @Test
    func `Delete an Internal Tag`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/internal_tags/123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows retrieving multiple internal tags of a particular space.
     * https://www.storyblok.com/docs/api/management/internal-tags/retrieve-multiple-internal-tags
     */
    @Test
    func `Retrieve Multiple Internal Tags`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/internal_tags")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows updating an internal tag using the numeric ID.
     * https://www.storyblok.com/docs/api/management/internal-tags/update-an-internal-tag
     */
    @Test
    func `Update an Internal Tag`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/internal_tags/123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "internal_tag": [
                "name": "Updated Tag name",
                "object_type": "asset",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}