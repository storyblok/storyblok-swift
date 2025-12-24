import Foundation
import Testing

@Suite struct `MAPI: FieldPlugins` {

    /**
     * This endpoint allows you to create a field type plugin.
     * https://www.storyblok.com/docs/api/management/field-plugins/create-a-field-plugin
     */
    @Test
    func `Create a Field Plugin`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/field_types/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "field_type": [
                "name": "my-geo-selector",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a field plugin by using its numeric id.
     * https://www.storyblok.com/docs/api/management/field-plugins/delete-a-field-plugin
     */
    @Test
    func `Delete a Field Plugin`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/field_types/1")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single field-type object with a specific numeric id.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-a-single-field-plugin
     */
    @Test
    func `Retrieve a Single Field Plugin`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/field_types/124")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single field-type object with a specific numeric id.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-a-single-field-plugin
     */
    @Test
    func `Retrieve a Single Field Plugin 2`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/org_field_types/124")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single field-type object with a specific numeric id.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-a-single-field-plugin
     */
    @Test
    func `Retrieve a Single Field Plugin 3`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/partner_field_types/124")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of field plugin objects. This endpoint is paged.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-multiple-field-plugins
     */
    @Test
    func `Retrieve Multiple Field Plugins`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/field_types/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of field plugin objects. This endpoint is paged.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-multiple-field-plugins
     */
    @Test
    func `Retrieve Multiple Field Plugins 2`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/org_field_types/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of field plugin objects. This endpoint is paged.
     * https://www.storyblok.com/docs/api/management/field-plugins/retrieve-multiple-field-plugins
     */
    @Test
    func `Retrieve Multiple Field Plugins 3`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/partner_field_types/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint can be used to perform updates to a field type plugin.
     * https://www.storyblok.com/docs/api/management/field-plugins/update-a-field-plugin
     */
    @Test
    func `Update a Field Plugin`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/field_types/123123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "field_type": [
                "body": "const Fieldtype = {}",
                "compiled_body": "",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}