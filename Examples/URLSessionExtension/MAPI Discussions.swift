import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: Discussions` {

    /**
     * This endpoint allows the creation of a comment in a particular discussion using the ID.
     * https://www.storyblok.com/docs/api/management/discussions/create-a-comment
     */
    @Test
    func `Create a Comment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/discussions/456/comments")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "comment": [
                "message_json": [
                    [
                        "text": "Hello new comment",
                        "type": "text",
                    ],
                ],
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint creates a new discussion.
     * https://www.storyblok.com/docs/api/management/discussions/create-a-discussion
     */
    @Test
    func `Create a Discussion`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/12367/discussions")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "discussion": [
                "block_uid": "f7bd92e3-b309-4441-a8a0-654e499fefc8",
                "comment": [
                    "message_json": [
                        [
                            "text": "this is a comment ",
                            "type": "text",
                        ],
                        [
                            "attrs": [
                                "id": 99734,
                                "label": "Fortune Ikechi",
                            ],
                            "type": "mention",
                        ],
                    ],
                ],
                "component": "feature",
                "fieldname": "name",
                "lang": "default",
                "title": "Name",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows deletion of a comment using the numeric ID.
     * https://www.storyblok.com/docs/api/management/discussions/delete-a-comment
     */
    @Test
    func `Delete a Comment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/discussions/456/comments/789")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Resolves a comment in a discussion.
     * https://www.storyblok.com/docs/api/management/discussions/resolve-a-discussion
     */
    @Test
    func `Resolve a Discussion`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/discussions/49468")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "discussion": [
                "solved_at": "2024-02-06T22:07:04.729Z",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Get a specific discussion.
     * https://www.storyblok.com/docs/api/management/discussions/retrieve-a-specific-discussion
     */
    @Test
    func `Retrieve a Specific Discussion`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/discussions/49473")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns comments for specific idea discussions from the Ideation Room.
     * https://www.storyblok.com/docs/api/management/discussions/retrieve-idea-discussions-comments
     */
    @Test
    func `Retrieve Idea Discussions Comments`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/ideas/1a2b3456-c7d8-9ef1-gh01-11i2jk13l14m/discussions")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve multiple comments from a specific discussion
     * https://www.storyblok.com/docs/api/management/discussions/retrieve-multiple-comments-from-a-specific-discussion
     */
    @Test
    func `Retrieve Multiple Comments from a Specific Discussion`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/discussions/49471/comments")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of discussion objects present inside a particular story. This endpoint is paged and can be filtered by using page=1 , status and per_page=1 for retrieving discussions per page.
     * https://www.storyblok.com/docs/api/management/discussions/retrieve-multiple-discussions
     */
    @Test
    func `Retrieve Multiple Discussions`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/1234/discussions")
        request.url!.append(queryItems: [
            URLQueryItem(name: "per_page", value: "1"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "by_status", value: "unsolved")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve your mentioned discussions. The response is paged.
     * https://www.storyblok.com/docs/api/management/discussions/retrieve-my-discussions
     */
    @Test
    func `Retrieve My Discussions`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/mentioned_discussions/me")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update comments in a particular discussion using the discussion ID and comment ID
     * https://www.storyblok.com/docs/api/management/discussions/update-a-comment
     */
    @Test
    func `Update a Comment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/discussions/2345/comments/456")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "comment": [
                "message_json": [
                    [
                        "text": "Updated Comment ",
                        "type": "text",
                    ],
                ],
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}