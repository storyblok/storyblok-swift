import Foundation
import Testing

@Suite struct `MAPI: DatasourceEntries` {

    /**
     * Create a datasource entry in a specific datasource
     * https://www.storyblok.com/docs/api/management/datasource-entries/create-a-datasource-entry
     */
    @Test
    func `Create a Datasource Entry`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasource_entries")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "datasource_entry": [
                "datasource_id": 12345,
                "name": "newsletter_text",
                "value": "Subscribe to our newsletter.",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a datasource entry using its numeric ID
     * https://www.storyblok.com/docs/api/management/datasource-entries/delete-a-datasource-entry
     */
    @Test
    func `Delete a Datasource Entry`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasource_entries/52")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a single datasource entry object with a specific numeric ID
     * https://www.storyblok.com/docs/api/management/datasource-entries/retrieve-a-single-datasource-entry
     */
    @Test
    func `Retrieve a Single Datasource Entry`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasource_entries/52")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a paginated array of datasource entry objects
     * https://www.storyblok.com/docs/api/management/datasource-entries/retrieve-multiple-datasource-entries
     */
    @Test
    func `Retrieve Multiple Datasource Entries`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasource_entries/?datasource_id=123&dimension=456")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a datasource entry using its numeric ID
     * https://www.storyblok.com/docs/api/management/datasource-entries/update-a-datasource-entry
     */
    @Test
    func `Update a Datasource Entry`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasource_entries/52")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "datasource_entry": [
                "name": "updated_newsletter_text",
                "value": "Update: Subscribe to our updated newsletter.",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a datasource entry using its numeric ID
     * https://www.storyblok.com/docs/api/management/datasource-entries/update-a-datasource-entry
     */
    @Test
    func `Update a Datasource Entry 2`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasource_entries/52")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "datasource_entry": [
                "dimension_value": "Changed the value in the dimension",
                "name": "updated_newsletter_text",
                "value": "Update: Sign up to our updated newsletter.",
            ],
            "dimension_id": 70466,
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}