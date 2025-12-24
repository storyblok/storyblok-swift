import Foundation
import Testing

@Suite struct `MAPI: Components` {

    /**
     * Create a component with properties available in the collaborator object
     * https://www.storyblok.com/docs/api/management/components/create-a-component
     */
    @Test
    func `Create a Component`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/components/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "component": [
                "display_name": nil,
                "is_nestable": true,
                "is_root": false,
                "name": "banner_section",
                "schema": [
                    "headline": [
                        "description": "This field is used to render a title",
                        "pos": 0,
                        "translatable": true,
                        "type": "text",
                    ],
                ],
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a component using its ID
     * https://www.storyblok.com/docs/api/management/components/delete-a-component
     */
    @Test
    func `Delete a Component`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/components/4321")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Restores a component to a saved version
     * https://www.storyblok.com/docs/api/management/components/restore-a-component-version
     */
    @Test
    func `Restore a Component Version`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/versions/279820276")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "model": "components",
            "model_id": 6826721,
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve the schema details of a component version
     * https://www.storyblok.com/docs/api/management/components/retrieve-a-single-component-version
     */
    @Test
    func `Retrieve a Single Component Version`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/components/6826721/component_versions/279820267")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a single component object using its ID
     * https://www.storyblok.com/docs/api/management/components/retrieve-a-single-component
     */
    @Test
    func `Retrieve a Single Component`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/components/4123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a paginated array of component versions
     * https://www.storyblok.com/docs/api/management/components/retrieve-component-versions
     */
    @Test
    func `Retrieve Component Versions`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/versions?model=components&model_id=6826721")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve an array of component objects
     * https://www.storyblok.com/docs/api/management/components/retrieve-multiple-components
     */
    @Test
    func `Retrieve Multiple Components`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/components/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update the values of a component
     * https://www.storyblok.com/docs/api/management/components/update-a-component
     */
    @Test
    func `Update a Component`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/components/4123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "component": [
                "display_name": nil,
                "id": 4123,
                "is_nestable": true,
                "is_root": false,
                "name": "banner_section",
                "schema": [
                    "headline": [
                        "description": "Use this field for the title",
                        "pos": 0,
                        "translatable": true,
                        "type": "text",
                    ],
                ],
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}