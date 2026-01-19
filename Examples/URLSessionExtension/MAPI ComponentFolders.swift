import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: ComponentFolders` {

    /**
     * Create a new component folder
     * https://www.storyblok.com/docs/api/management/component-folders/create-a-component-folder
     */
    @Test
    func `Create a Component Folder`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/component_groups/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "component_group": [
                "name": "Teasers",
                "parent_id": "123123",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a component folder using its numeric ID
     * https://www.storyblok.com/docs/api/management/component-folders/delete-a-component-folder
     */
    @Test
    func `Delete a Component Folder`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/component_groups/4123")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a single component folder object using its ID
     * https://www.storyblok.com/docs/api/management/component-folders/retrieve-a-single-component-folder
     */
    @Test
    func `Retrieve a Single Component Folder`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/component_groups/4123")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a paginated array of component folder objects
     * https://www.storyblok.com/docs/api/management/component-folders/retrieve-multiple-component-folders
     */
    @Test
    func `Retrieve Multiple Component Folders`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/component_groups/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a specific component folder
     * https://www.storyblok.com/docs/api/management/component-folders/update-a-component-folder
     */
    @Test
    func `Update a Component folder`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/component_groups/4123")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "component_group": [
                "name": "New Teaser Name",
                "parent_id": 123123,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}