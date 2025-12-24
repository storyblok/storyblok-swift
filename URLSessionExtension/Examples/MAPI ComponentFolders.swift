import Foundation
import Testing

@Suite struct `MAPI: ComponentFolders` {

    /**
     * Create a new component folder
     * https://www.storyblok.com/docs/api/management/component-folders/create-a-component-folder
     */
    @Test
    func `Create a Component Folder`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/component_groups/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "component_group": [
                "name": "Teasers",
                "parent_id": "123123",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a component folder using its numeric ID
     * https://www.storyblok.com/docs/api/management/component-folders/delete-a-component-folder
     */
    @Test
    func `Delete a Component Folder`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/component_groups/4123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a single component folder object using its ID
     * https://www.storyblok.com/docs/api/management/component-folders/retrieve-a-single-component-folder
     */
    @Test
    func `Retrieve a Single Component Folder`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/component_groups/4123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a paginated array of component folder objects
     * https://www.storyblok.com/docs/api/management/component-folders/retrieve-multiple-component-folders
     */
    @Test
    func `Retrieve Multiple Component Folders`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/component_groups/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a specific component folder
     * https://www.storyblok.com/docs/api/management/component-folders/update-a-component-folder
     */
    @Test
    func `Update a Component folder`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/component_groups/4123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "component_group": [
                "name": "New Teaser Name",
                "parent_id": 123123,
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}