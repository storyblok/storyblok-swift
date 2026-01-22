import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: DatasourceEntries` {

    /**
     * Create a datasource entry in a specific datasource
     * https://www.storyblok.com/docs/api/management/datasource-entries/create-a-datasource-entry
     */
    @Test
    func `Create a Datasource Entry`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/datasource_entries")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "datasource_entry": [
                "datasource_id": 12345,
                "name": "newsletter_text",
                "value": "Subscribe to our newsletter.",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a datasource entry using its numeric ID
     * https://www.storyblok.com/docs/api/management/datasource-entries/delete-a-datasource-entry
     */
    @Test
    func `Delete a Datasource Entry`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/datasource_entries/52")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a single datasource entry object with a specific numeric ID
     * https://www.storyblok.com/docs/api/management/datasource-entries/retrieve-a-single-datasource-entry
     */
    @Test
    func `Retrieve a Single Datasource Entry`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/datasource_entries/52")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a paginated array of datasource entry objects
     * https://www.storyblok.com/docs/api/management/datasource-entries/retrieve-multiple-datasource-entries
     */
    @Test
    func `Retrieve Multiple Datasource Entries`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/datasource_entries/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "datasource_id", value: "123"),
            URLQueryItem(name: "dimension", value: "456")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a datasource entry using its numeric ID
     * https://www.storyblok.com/docs/api/management/datasource-entries/update-a-datasource-entry
     */
    @Test
    func `Update a Datasource Entry`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/datasource_entries/52")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "datasource_entry": [
                "name": "updated_newsletter_text",
                "value": "Update: Subscribe to our updated newsletter.",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a datasource entry using its numeric ID
     * https://www.storyblok.com/docs/api/management/datasource-entries/update-a-datasource-entry
     */
    @Test
    func `Update a Datasource Entry 2`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/datasource_entries/52")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "datasource_entry": [
                "dimension_value": "Changed the value in the dimension",
                "name": "updated_newsletter_text",
                "value": "Update: Sign up to our updated newsletter.",
            ],
            "dimension_id": 70466,
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}
