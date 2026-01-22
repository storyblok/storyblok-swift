import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: Stories` {

    /**
     * This endpoint returns the story content, translated by AI.
     * https://www.storyblok.com/docs/api/management/stories/ai-translate
     */
    @Test
    func `Translate a Story by AI`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/536503907/ai_translate")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": "fr",
            "lang": "fr",
            "overwrite": true,
            "release_id": 0,
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * With this endpoint you can compare the changes between two versions of a story in Storyblok. You need to provide the story ID and version ID in the request to retrieve the comparison results.
     * https://www.storyblok.com/docs/api/management/stories/compare-a-story-version
     */
    @Test
    func `Compare a Story Version`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/267/compare")
        request.url!.append(queryItems: [
            URLQueryItem(name: "version", value: "151")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * You can set most of the fields that are available in the story object, below we only list the properties in the example and the possible required fields. Stories are not published by default. If you want to create a published story add the parameter publish with the value 1.
     * https://www.storyblok.com/docs/api/management/stories/create-a-story
     */
    @Test
    func `Create a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "publish": 1,
            "story": [
                "content": [
                    "body": [ ],
                    "component": "page",
                ],
                "name": "Story Name",
                "slug": "story-name",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Use the Story endpoint to create and manage content folders.
     * https://www.storyblok.com/docs/api/management/stories/create-and-manage-folders
     */
    @Test
    func `Create and Manage Folders`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "story": [
                "is_folder": true,
                "name": "A new folder",
                "parent_id": 0,
                "slug": "a-new-folder",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Use the Story endpoint to create and manage content folders.
     * https://www.storyblok.com/docs/api/management/stories/create-and-manage-folders
     */
    @Test
    func `Create and Manage Folders 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "story": [
                "default_root": "article",
                "is_folder": true,
                "name": "A new folder",
                "parent_id": 0,
                "slug": "a-new-folder",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Use the Story endpoint to create and manage content folders.
     * https://www.storyblok.com/docs/api/management/stories/create-and-manage-folders
     */
    @Test
    func `Create and Manage Folders 3`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "story": [
                "content": [
                    "content_types": [
                        "category",
                    ],
                    "lock_subfolders_content_types": false,
                ],
                "is_folder": true,
                "name": "Categories",
                "parent_id": 0,
                "slug": "categories",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a content entry by using its numeric id.
     * https://www.storyblok.com/docs/api/management/stories/delete-a-story
     */
    @Test
    func `Delete a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/2141")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint can be used to duplicate a story into another folder.
     * https://www.storyblok.com/docs/api/management/stories/duplicate-a-story
     */
    @Test
    func `Duplicate a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/531458099/duplicate")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "same_path": true,
            "story": [
                "group_id": "4f77133f-bb1c-4799-a54d-b6217107247f",
            ],
            "target_dimension": 531452775,
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Exporting a story can be done using a GET request for each story you want to export.
     * https://www.storyblok.com/docs/api/management/stories/export-a-story
     */
    @Test
    func `Export a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/export.json")
        request.url!.append(queryItems: [
            URLQueryItem(name: "lang_code", value: "pt-br"),
            URLQueryItem(name: "export_lang", value: "true")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Exporting a story can be done using a GET request for each story you want to export.
     * https://www.storyblok.com/docs/api/management/stories/export-a-story
     */
    @Test
    func `Export a Story 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/export.json")
        request.url!.append(queryItems: [
            URLQueryItem(name: "lang_code", value: "pt-br"),
            URLQueryItem(name: "export_lang", value: "true"),
            URLQueryItem(name: "version", value: "2")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve the versions of a story.
     * https://www.storyblok.com/docs/api/management/stories/get-story-versions-new
     */
    @Test
    func `Get Story Versions`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/story_versions")
        request.url!.append(queryItems: [
            URLQueryItem(name: "by_story_id", value: "174957")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This allows you to retrieve the versions of a story and the corresponding author information. You can also filter the results based on pagination using the page parameter. This can be done with a GET request on the story version you wish to retrieve.
     * https://www.storyblok.com/docs/api/management/stories/get-story-versions
     */
    @Test
    func `Get Story Versions (Legacy)`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/123/versions")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This allows you to retrieve the versions of a story and the corresponding author information. You can also filter the results based on pagination using the page parameter. This can be done with a GET request on the story version you wish to retrieve.
     * https://www.storyblok.com/docs/api/management/stories/get-story-versions
     */
    @Test
    func `Get Story Versions (Legacy) 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/123/versions")
        request.url!.append(queryItems: [
            URLQueryItem(name: "page", value: "2")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint is used to get unpublished dependencies of a story.
     * https://www.storyblok.com/docs/api/management/stories/get-unpublished-dependencies
     */
    @Test
    func `Get Unpublished Dependencies`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/unpublished_dependencies")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "story_ids": [
                522672112,
                534980620,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Importing a story can be done using a PUT request for each story you want to import.
     * https://www.storyblok.com/docs/api/management/stories/import-a-story
     */
    @Test
    func `Import a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/import.json")
        request.url!.append(queryItems: [
            URLQueryItem(name: "lang_code", value: "pt-br"),
            URLQueryItem(name: "import_lang", value: "true")
        ])
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "story": [
                "alternates": [ ],
                "breadcrumbs": [ ],
                "can_not_view": nil,
                "content": [
                    "_uid": "98cccd01-f807-4494-996d-c6b0de2045a5",
                    "component": "your_content_type",
                ],
                "created_at": "2023-05-29T09:53:40.231Z",
                "default_root": nil,
                "deleted_at": nil,
                "disble_fe_editor": false,
                "expire_at": nil,
                "favourite_for_user_ids": [ ],
                "first_published_at": "2023-06-06T08:47:05.426Z",
                "full_slug": "home",
                "group_id": "fb33b858-277f-4690-81fb-e0a080bd39ac",
                "id": 314931981,
                "imported_at": "2024-02-08T11:26:42.505Z",
                "is_folder": false,
                "is_scheduled": nil,
                "is_startpage": false,
                "last_author": [
                    "friendly_name": "Storyblok",
                    "id": 39821,
                    "userid": "storyblok",
                ],
                "localized_paths": [
                    [ ],
                ],
                "meta_data": nil,
                "name": "Home",
                "parent": nil,
                "parent_id": 0,
                "path": nil,
                "pinned": false,
                "position": 0,
                "preview_token": [
                    "timestamp": "1545530576",
                    "token": "279395174a25be38b702f9ec90d08a960e1a5a84",
                ],
                "publish_at": nil,
                "published": true,
                "published_at": "2023-08-30T09:16:42.066Z",
                "scheduled_dates": nil,
                "slug": "home",
                "sort_by_date": nil,
                "space_role_ids": [ ],
                "tag_list": [ ],
                "translated_slugs": [
                    [ ],
                ],
                "translated_stories": [ ],
                "unpublished_changes": true,
                "updated_at": "2024-02-08T11:26:42.514Z",
                "user_ids": [
                    12345,
                ],
                "uuid": "2497c493-168a-443f-bbb1-ccfd6340d319",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Publishing a story (besides using the publish property via creation) can be done by sending a GET request for each story you want to publish with story_id using the following endpoint.Multiple language versions of a story can be published using the lang parameter (Publish translations individually has to be enabled in Settings > Internationalization).
     * https://www.storyblok.com/docs/api/management/stories/publish-a-story
     */
    @Test
    func `Publish a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/2141/publish")
        request.url!.append(queryItems: [
            URLQueryItem(name: "lang", value: "de")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint lets you restore a story to a specific version.
     * https://www.storyblok.com/docs/api/management/stories/restore-a-story-version
     */
    @Test
    func `Restore a Story Version`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/623949938/restore_with")
        request.url!.append(queryItems: [
            URLQueryItem(name: "version", value: "55648825"),
            URLQueryItem(name: "versions_v2", value: "true")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint returns an array of story objects without content. Stories can be filtered with the parameters below. The response is paged.
     * https://www.storyblok.com/docs/api/management/stories/retrieve-multiple-stories
     */
    @Test
    func `Retrieve Multiple Stories`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint returns an array of story objects without content. Stories can be filtered with the parameters below. The response is paged.
     * https://www.storyblok.com/docs/api/management/stories/retrieve-multiple-stories
     */
    @Test
    func `Retrieve Multiple Stories 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "text_search", value: "My fulltext search")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint returns an array of story objects without content. Stories can be filtered with the parameters below. The response is paged.
     * https://www.storyblok.com/docs/api/management/stories/retrieve-multiple-stories
     */
    @Test
    func `Retrieve Multiple Stories 3`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "by_uuids", value: "fb3afwa58-277f-4690-81fb-e0a080bd39ac,81fb81fb-e9fa-42b5-b952-c7d96ab6099d")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint returns a single, fully loaded story object by providing a specific numeric id.
     * https://www.storyblok.com/docs/api/management/stories/retrieve-one-story
     */
    @Test
    func `Retrieve One Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/369689")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Unpublishing a story (besides using the unpublish action in visual editor or in content viewer) can be done by using a GET request for each story you want to unpublish. Multiple language versions of a story can be unpublished using the lang parameter (Publish translations individually has to be enabled in Settings > Internationalization).
     * https://www.storyblok.com/docs/api/management/stories/unpublish-a-story
     */
    @Test
    func `Unpublish a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/2141/unpublish")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Use this endpoint for migrations, updates (new component structure, and more), or bulk actions
     * https://www.storyblok.com/docs/api/management/stories/update-a-story
     */
    @Test
    func `Update a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/2141")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "force_update": 1,
            "publish": 1,
            "story": [
                "content": [
                    "body": [ ],
                    "component": "page",
                ],
                "id": 2141,
                "name": "Updated Story Name",
                "slug": "story-name",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}
