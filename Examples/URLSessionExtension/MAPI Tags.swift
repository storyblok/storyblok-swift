import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: Tags` {

    /**
     * Create a new tag and assign it to a story
     * https://www.storyblok.com/docs/api/management/tags/create-a-tag
     */
    @Test
    func `Create a Tag`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tags")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "tag": [
                "name": "Editor's choice",
                "story_id": 202,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a tag from a space
     * https://www.storyblok.com/docs/api/management/tags/delete-a-tag
     */
    @Test
    func `Delete a Tag`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tags/test-tag")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a paginated array of tag objects from the specified space
     * https://www.storyblok.com/docs/api/management/tags/retrieve-multiple-tags
     */
    @Test
    func `Retrieve Multiple Tags`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tags/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "search", value: "Featured")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a paginated array of tag objects from the specified space
     * https://www.storyblok.com/docs/api/management/tags/retrieve-multiple-tags
     */
    @Test
    func `Retrieve Multiple Tags 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tags/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "all_tags", value: "true"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "per_page", value: "5")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Assign one or more tags to multiple stories at once
     * https://www.storyblok.com/docs/api/management/tags/tag-bulk-association
     */
    @Test
    func `Tag Bulk Association`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tags/bulk_association")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "tags": [
                "stories": [
                    [
                        "story_id": 69934114531566,
                        "tag_list": [
                            "Editor's choice",
                            "Featured",
                        ],
                    ],
                ],
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update an existing tag
     * https://www.storyblok.com/docs/api/management/tags/update-a-tag
     */
    @Test
    func `Update a Tag`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tags/Featured")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "tag": [
                "name": "featured",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}