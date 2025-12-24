import Foundation
import Testing

@Suite struct `MAPI: Tags` {

    /**
     * You can create a tag, and optionally add it to a story.
     * https://www.storyblok.com/docs/api/management/tags/create-a-tag
     */
    @Test
    func `Create a Tag`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/tags")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "tag": [
                "name": "Editor's Choice",
                "story_id": 202,
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a tag from a space.
     * https://www.storyblok.com/docs/api/management/tags/delete-a-tag
     */
    @Test
    func `Delete a Tag`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/stories/2141")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint returns an array of tag objects from a space.
     * https://www.storyblok.com/docs/api/management/tags/retrieve-multiple-tags
     */
    @Test
    func `Retrieve Multiple Tags`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/tags/?search=article")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint returns an array of tag objects from a space.
     * https://www.storyblok.com/docs/api/management/tags/retrieve-multiple-tags
     */
    @Test
    func `Retrieve Multiple Tags 2`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/stories/?all_tags=true")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint is used to add a tag to multiple stories at once.
     * https://www.storyblok.com/docs/api/management/tags/tag-bulk-association
     */
    @Test
    func `Tag Bulk Association`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/tags/bulk_association")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "tags": [
                "stories": [
                    [
                        "story_id": 69934114531566,
                        "tag_list": [
                            "Editor's Choice",
                            "Featured",
                        ],
                    ],
                ],
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint can be used to edit the name of a tag.
     * https://www.storyblok.com/docs/api/management/tags/update-a-tag
     */
    @Test
    func `Update a Tag`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/stories/2141")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "id": "Editor's Choice",
            "tag": [
                "name": "Editorial",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}