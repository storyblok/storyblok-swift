import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: InternalTags` {

    /**
     * This endpoint allows creating an internal tag inside a particular space.
     * https://www.storyblok.com/docs/api/management/internal-tags/create-an-internal-tag
     */
    @Test
    func `Create an Internal Tag`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/internal_tags")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "internal_tag": [
                "name": "New Release",
                "object_type": "component",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows deleting an internal tag using the numeric ID.
     * https://www.storyblok.com/docs/api/management/internal-tags/delete-an-internal-tag
     */
    @Test
    func `Delete an Internal Tag`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/internal_tags/123")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows retrieving multiple internal tags of a particular space.
     * https://www.storyblok.com/docs/api/management/internal-tags/retrieve-multiple-internal-tags
     */
    @Test
    func `Retrieve Multiple Internal Tags`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/internal_tags")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows updating an internal tag using the numeric ID.
     * https://www.storyblok.com/docs/api/management/internal-tags/update-an-internal-tag
     */
    @Test
    func `Update an Internal Tag`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/internal_tags/123")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "internal_tag": [
                "name": "Updated Tag name",
                "object_type": "asset",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}
