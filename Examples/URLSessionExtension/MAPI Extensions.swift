import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: Extensions` {

    /**
     * This endpoint allows you to create an extension inside the organization or partner extensions.
     * https://www.storyblok.com/docs/api/management/extensions/create-an-extension
     */
    @Test
    func `Create an Extension`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "org_apps")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "app": [
                "name": "My extension",
                "slug": "storyblok-gmbh@extension-1",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows to delete organization and partner extensions by using the numeric ID.
     * https://www.storyblok.com/docs/api/management/extensions/delete-an-extension
     */
    @Test
    func `Delete an Extension`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "org_apps/123123")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve all the plugins from organization or the partner portal.
     * https://www.storyblok.com/docs/api/management/extensions/retrieve-all-extensions
     */
    @Test
    func `Retrieve all Extensions`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "org_apps/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve all the plugins from organization or the partner portal.
     * https://www.storyblok.com/docs/api/management/extensions/retrieve-all-extensions
     */
    @Test
    func `Retrieve all Extensions 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "partner_apps/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a specific plugin from organization or the partner extensions.
     * https://www.storyblok.com/docs/api/management/extensions/retrieve-an-extension
     */
    @Test
    func `Retrieve an Extension`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "org_apps/123")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a specific plugin from organization or the partner extensions.
     * https://www.storyblok.com/docs/api/management/extensions/retrieve-an-extension
     */
    @Test
    func `Retrieve an Extension 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "partner_apps/123")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve settings of an extension by the numeric ID. To do so, obtain an OAuth token or a Personal Access Token. This endpoints gives both the app and app_provision objects in the response for the specific extension.
     * https://www.storyblok.com/docs/api/management/extensions/retrieve-settings-of-a-plugin
     */
    @Test
    func `Retrieve Settings of an Installed Extension`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/app_provisions/123123")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve settings of all extensions of a particular space. To do so, obtain an OAuth token or a Personal Access Token.
     * https://www.storyblok.com/docs/api/management/extensions/retrieve-settings-of-all-installed-extensions
     */
    @Test
    func `Retrieve Settings of all Installed Extensions`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/app_provisions/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows you to update an extension, specifically the app object using the numeric ID.
     * https://www.storyblok.com/docs/api/management/extensions/update-an-extension
     */
    @Test
    func `Update an Extension`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "org_apps/a8d372f8-5659-4f77-b549-0a82ff9c6e72")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "app": [
                "enable_space_settings": true,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update settings such as plugin properties inside Space Plugins and Tool Plugins. To do so, obtain an OAuth token or a Personal Access Token.
     * https://www.storyblok.com/docs/api/management/extensions/update-install-plugin-settings
     */
    @Test
    func `Update Installed Extension Settings`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/app_provisions/a8d372f8-5659-4f77-b549-0a82ff9c6e72")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "app_provision": [
                "space_level_settings": [
                    "any_setting_1": "hello",
                    "any_setting_2": 123456,
                ],
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}
