import Foundation
import Testing

@Suite struct `MAPI: IdeationRoom` {

    /**
     * This endpoint is to create an Idea in the Ideation Room. In the request body, passing name in the idea object is a minimum requirement.
     * https://www.storyblok.com/docs/api/management/ideation-room/create-an-idea
     */
    @Test
    func `Create an Idea`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/ideas")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "idea": [
                "assignee": nil,
                "author": [
                    "avatar": "avatars/67891/838dcb304c/avatar.jpg",
                    "friendly_name": "Jon Doe",
                    "id": 67891,
                    "userid": "test@email.com",
                ],
                "bookmarks": [ ],
                "content": [ ],
                "deleted_at": nil,
                "description": "First idea",
                "internal_tag_ids": [
                    "12345",
                ],
                "internal_tags_list": [
                    [
                        "id": 12345,
                        "name": "docs",
                    ],
                ],
                "is_private": true,
                "name": "My first idea",
                "status": "draft",
                "stories": [ ],
                "story_ids": [ ],
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows the deletion of an idea using the uuid.
     * https://www.storyblok.com/docs/api/management/ideation-room/delete-an-idea
     */
    @Test
    func `Delete an Idea`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/ideas/123ab45c-6d78-9101-11ef-213gh1i4j1k5")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows restoring an idea using the uuid. Use deleted idea's id value for idea_id. This endpoint also restores the idea's discussion comments.
     * https://www.storyblok.com/docs/api/management/ideation-room/restore-an-idea
     */
    @Test
    func `Restore an Idea`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/ideas/123ab45c-6d78-9101-11ef-213gh1i4j1k5")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns discussions in an idea.
     * https://www.storyblok.com/docs/api/management/ideation-room/retrieve-discussions-in-idea
     */
    @Test
    func `Retrieve Discussions in Idea`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/ideas/1a2b3456-c7d8-9ef1-gh01-11i2jk13l14m/discussions")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of idea objects.
     * https://www.storyblok.com/docs/api/management/ideation-room/retrieve-multiple-ideas
     */
    @Test
    func `Retrieve Multiple Ideas`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/ideas/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single idea object by providing a specific numeric id.
     * https://www.storyblok.com/docs/api/management/ideation-room/retrieve-one-idea
     */
    @Test
    func `Retrieve One Idea`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/ideas/1a2b3456-c7d8-9ef1-gh01-11i2jk13l14m")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update an idea using an idea uuid. In the request body, it's required to pass the idea object.
     * https://www.storyblok.com/docs/api/management/ideation-room/update-an-idea
     */
    @Test
    func `Update an Idea`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/ideas/ab123cd4-5e6f-7gh8-9ij1-01k112l13m1n")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "idea": [
                "assignee": nil,
                "author": [
                    "avatar": "avatars/67891/838dcb304c/avatar.jpg",
                    "friendly_name": "Jon Doe",
                    "id": 67891,
                    "userid": "test@email.com",
                ],
                "bookmarks": [ ],
                "content": [ ],
                "deleted_at": nil,
                "description": "First idea",
                "internal_tag_ids": [
                    "12345",
                ],
                "internal_tags_list": [
                    [
                        "id": 12345,
                        "name": "docs",
                    ],
                ],
                "is_private": true,
                "name": "My first idea",
                "status": "draft",
                "stories": [ ],
                "story_ids": [ ],
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}