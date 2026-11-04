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
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/267/compare")
        request.url!.append(queryItems: [
            URLQueryItem(name: "version", value: "151")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * You can set most of the fields that are available in the story object, below we only list the properties in the example and the possible required fields. Stories are not published by default. If you want to create a published story add the parameter publish with the value true.
     * https://www.storyblok.com/docs/api/management/stories/create-a-story
     */
    @Test
    func `Create a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "publish": true,
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
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/182794698822337")
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
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
     * Retrieve the versions of a story.
     * https://www.storyblok.com/docs/api/management/stories/get-story-versions-new
     */
    @Test
    func `Get Story Versions`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
    func `Get Story Versions Legacy`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/123/versions")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This allows you to retrieve the versions of a story and the corresponding author information. You can also filter the results based on pagination using the page parameter. This can be done with a GET request on the story version you wish to retrieve.
     * https://www.storyblok.com/docs/api/management/stories/get-story-versions
     */
    @Test
    func `Get Story Versions Legacy 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
     * Publishing a story (besides using the publish property via creation) can be done by sending a GET request for each story you want to publish with story_id using the following endpoint.Multiple language versions of a story can be published using the lang parameter (Publish translations individually has to be enabled in Settings &gt; Internationalization).
     * https://www.storyblok.com/docs/api/management/stories/publish-a-story
     */
    @Test
    func `Publish a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/623949938/restore_with")
        request.url!.append(queryItems: [
            URLQueryItem(name: "version", value: "55648825"),
            URLQueryItem(name: "versions_v2", value: "true")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * A paged endpoint that returns an array of story objects without content. Use supported parameters to filter stories.
     * https://www.storyblok.com/docs/api/management/stories/retrieve-multiple-stories
     */
    @Test
    func `Retrieve Multiple Stories Management API`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * A paged endpoint that returns an array of story objects without content. Use supported parameters to filter stories.
     * https://www.storyblok.com/docs/api/management/stories/retrieve-multiple-stories
     */
    @Test
    func `Retrieve Multiple Stories Management API 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "text_search", value: "My fulltext search")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * A paged endpoint that returns an array of story objects without content. Use supported parameters to filter stories.
     * https://www.storyblok.com/docs/api/management/stories/retrieve-multiple-stories
     */
    @Test
    func `Retrieve Multiple Stories Management API 3`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
    func `Retrieve a Single Story Management API`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/369689")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Unpublishing a story (besides using the unpublish action in visual editor or in content viewer) can be done by using a GET request for each story you want to unpublish. Multiple language versions of a story can be unpublished using the lang parameter (Publish translations individually has to be enabled in Settings &gt; Internationalization).
     * https://www.storyblok.com/docs/api/management/stories/unpublish-a-story
     */
    @Test
    func `Unpublish a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
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
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/2141")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "force_update": 1,
            "publish": true,
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

    /**
     * Examples for exporting and importing stories as JSON.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-json-examples
     */
    @Test
    func `Examples Export Import a story JSON`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/88751/stories/64181051491446/export.json")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as JSON.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-json-examples
     */
    @Test
    func `Examples Export Import a story JSON 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/export.json")
        request.url!.append(queryItems: [
            URLQueryItem(name: "lang_code", value: "sw"),
            URLQueryItem(name: "export_lang", value: "true")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as JSON.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-json-examples
     */
    @Test
    func `Examples Export Import a story JSON 3`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/export.json")
        request.url!.append(queryItems: [
            URLQueryItem(name: "lang_code", value: "pt-br"),
            URLQueryItem(name: "export_lang", value: "true"),
            URLQueryItem(name: "version", value: "1")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as JSON.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-json-examples
     */
    @Test
    func `Examples Export Import a story JSON 4`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/import.json")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "data": "{\"a5a68c3e-876d-4d5e-b08f-e000efafe41d:feature:name\":\"HiHallo\",\"d31919a3-a807-4274-9820-0bf87f7ba03c:page:text\":\"Blog Posts\",\"ffa153ea-8f63-467f-b370-65d5dd3d710f:paragraph:@richtext:richtext/content[0:paragraph].content[0].text\":\"\\\"Hark, what light through yonder editor breaks?\\\" Just our AI generating your next very epic storyline. \",\"ffa153ea-8f63-467f-b370-65d5dd3d710f:paragraph:@richtext:richtext/content[0:paragraph].content[2].text\":\"Speed up asset creation and balance gameplay, all with a few clicks. Give your small studio big-story power. #indiegamedev #ai #gamedevelopment\",\"language\":\"default\",\"page\":\"314931981\",\"text_nodes\":0,\"url\":\"home\"}",
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as JSON.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-json-examples
     */
    @Test
    func `Examples Export Import a story JSON 5`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/import.json")
        request.url!.append(queryItems: [
            URLQueryItem(name: "lang_code", value: "es"),
            URLQueryItem(name: "import_lang", value: "true")
        ])
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "data": "{\"59ea90a7-c548-4d96-ae11-3d4ed40a5176:dp_richtext:richtext:content/content[0].content[0].text\":\"Translated content\",\"language\":\"es\",\"page\":\"314931981\",\"text_nodes\":1,\"url\":\"home\"}",
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as JSON.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-json-examples
     */
    @Test
    func `Examples Export Import a story JSON 6`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/import.json")
        request.url!.append(queryItems: [
            URLQueryItem(name: "version", value: "1")
        ])
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "data": "{\"a5a68c3e-876d-4d5e-b08f-e000efafe41d:feature:name\":\"Hallo! Release\",\"ffa153ea-8f63-467f-b370-65d5dd3d710f:paragraph:@richtext:richtext\":\"{\\\"type\\\":\\\"doc\\\",\\\"content\\\":[{\\\"type\\\":\\\"paragraph\\\",\\\"attrs\\\":{\\\"textAlign\\\":null},\\\"content\\\":[{\\\"text\\\":\\\"\\\\\\\"Hark, what light through yonder editor breaks?\\\\\\\" Just our AI generating your next very epic storyline. \\\",\\\"type\\\":\\\"text\\\"},{\\\"type\\\":\\\"emoji\\\",\\\"attrs\\\":{\\\"name\\\":\\\"wink\\\",\\\"emoji\\\":\\\"😉\\\",\\\"fallbackImage\\\":\\\"https://cdn.jsdelivr.net/npm/emoji-datasource-apple/img/apple/64/1f609.png\\\"}},{\\\"text\\\":\\\" Speed up asset creation and balance gameplay, all with a few clicks. Give your small studio big-story power. #indiegamedev #ai #gamedevelopment2\\\",\\\"type\\\":\\\"text\\\"}]}]}\",\"d31919a3-a807-4274-9820-0bf87f7ba03c:page:text\":\"Blog Posts\",\"page\":\"623949938\",\"language\":\"default\",\"url\":\"home\",\"text_nodes\":0}",
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as XML.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-xml-examples
     */
    @Test
    func `Examples Export Import a story XML`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/export.xml")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as XML.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-xml-examples
     */
    @Test
    func `Examples Export Import a story XML 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/export.xml")
        request.url!.append(queryItems: [
            URLQueryItem(name: "lang_code", value: "it"),
            URLQueryItem(name: "export_lang", value: "true")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as XML.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-xml-examples
     */
    @Test
    func `Examples Export Import a story XML 3`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/export.xml")
        request.url!.append(queryItems: [
            URLQueryItem(name: "lang_code", value: "pt-br"),
            URLQueryItem(name: "export_lang", value: "true"),
            URLQueryItem(name: "version", value: "1")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as XML.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-xml-examples
     */
    @Test
    func `Examples Export Import a story XML 4`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/import.xml")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "data": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<page text_nodes=\"0\" filename=\"home\" url=\"home\" id=\"314931981\" language=\"default\">\n<name>Home</name>\n<tags>\n  <tag id=\"ebf2eb36-2a3b-4231-b039-7a64178f50c2:feature:title\" type=\"STRING\">\n    <text><![CDATA[Home Page Title]]></text>\n  </tag>\n</tags>\n</page>",
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as XML.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-xml-examples
     */
    @Test
    func `Examples Export Import a story XML 5`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/import.xml")
        request.url!.append(queryItems: [
            URLQueryItem(name: "lang_code", value: "pt-br"),
            URLQueryItem(name: "import_lang", value: "true")
        ])
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "data": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<page text_nodes=\"0\" filename=\"home\" url=\"home\" id=\"314931981\" language=\"pt-br\">\n<name>Home</name>\n<tags>\n  <tag id=\"ebf2eb36-2a3b-4231-b039-7a64178f50c2:feature:title\" type=\"STRING\">\n    <text><![CDATA[Título traduzido]]></text>\n  </tag>\n  <tag id=\"ebf2eb36-2a3b-4231-b039-7a64178f50c2:feature:subtitle\" type=\"STRING\">\n    <text><![CDATA[Subtítulo traduzido]]></text>\n  </tag>\n</tags>\n</page>",
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Examples for exporting and importing stories as XML.
     * https://www.storyblok.com/docs/api/management/stories/examples/export-import-xml-examples
     */
    @Test
    func `Examples Export Import a story XML 6`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/stories/314931981/import.xml")
        request.url!.append(queryItems: [
            URLQueryItem(name: "version", value: "1")
        ])
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "data": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<page filename=\"home\" id=\"314931981\" language=\"default\">\n<name>Home</name>\n<tags>\n  <tag id=\"richtext\" type=\"STRING\">\n    <text><![CDATA[{\"type\":\"doc\",\"content\":[{\"type\":\"paragraph\",\"content\":[{\"text\":\"Example richtext content.\",\"type\":\"text\"}]}]}]]></text>\n  </tag>\n</tags>\n</page>",
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}