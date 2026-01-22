import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: FieldPlugins` {

    /**
     * This endpoint allows you to create a field type plugin.
     * https://www.storyblok.com/docs/api/management/field-plugins/create-a-field-plugin
     */
    @Test
    func `Create a Field Plugin`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "field_types/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "field_type": [
                "name": "my-geo-selector",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a field plugin by using its numeric id.
     * https://www.storyblok.com/docs/api/management/field-plugins/delete-a-field-plugin
     */
    @Test
    func `Delete a Field Plugin`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "field_types/1")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single field-type object with a specific numeric id.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-a-single-field-plugin
     */
    @Test
    func `Retrieve a Single Field Plugin`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "field_types/124")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single field-type object with a specific numeric id.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-a-single-field-plugin
     */
    @Test
    func `Retrieve a Single Field Plugin 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "org_field_types/124")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single field-type object with a specific numeric id.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-a-single-field-plugin
     */
    @Test
    func `Retrieve a Single Field Plugin 3`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "partner_field_types/124")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of field plugin objects. This endpoint is paged.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-multiple-field-plugins
     */
    @Test
    func `Retrieve Multiple Field Plugins`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "field_types/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of field plugin objects. This endpoint is paged.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-multiple-field-plugins
     */
    @Test
    func `Retrieve Multiple Field Plugins 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "org_field_types/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of field plugin objects. This endpoint is paged.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-multiple-field-plugins
     */
    @Test
    func `Retrieve Multiple Field Plugins 3`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "partner_field_types/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint can be used to perform updates to a field type plugin.
     * https://www.storyblok.com/docs/api/management/field-plugins/update-a-field-plugin
     */
    @Test
    func `Update a Field Plugin`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "field_types/123123")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "field_type": [
                "body": "const Fieldtype = {}",
                "compiled_body": "",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}
