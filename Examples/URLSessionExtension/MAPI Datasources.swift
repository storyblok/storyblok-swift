import Foundation
import Testing

@Suite struct `MAPI: Datasources` {

    /**
     * Create a new datasource
     * https://www.storyblok.com/docs/api/management/datasources/create-a-datasource
     */
    @Test
    func `Create a Datasource`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasources/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "datasource": [
                "name": "Labels for Website",
                "slug": "labels",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Create a new datasource
     * https://www.storyblok.com/docs/api/management/datasources/create-a-datasource
     */
    @Test
    func `Create a Datasource 2`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasources/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "datasource": [
                "dimensions_attributes": [
                    [
                        "entry_value": "es",
                        "name": "Spanish",
                    ],
                    [
                        "entry_value": "de",
                        "name": "German",
                    ],
                ],
                "name": "Labels for Website",
                "slug": "label",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a datasource using its numeric ID
     * https://www.storyblok.com/docs/api/management/datasources/delete-a-datasource
     */
    @Test
    func `Delete a Datasource`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasources/91")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a single datasource using its numeric ID
     * https://www.storyblok.com/docs/api/management/datasources/retrieve-a-single-datasource
     */
    @Test
    func `Retrieve a Single Datasource`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasources/91")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a paginated array of datasource objects
     * https://www.storyblok.com/docs/api/management/datasources/retrieve-multiple-datasources
     */
    @Test
    func `Retrieve Multiple Datasources`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasources/?search=Labels+for+Website")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a datasource using it numeric ID
     * https://www.storyblok.com/docs/api/management/datasources/update-a-datasource
     */
    @Test
    func `Update a Datasource`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasources/91")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "datasource": [
                "name": "Labels for Website",
                "slug": "labels_for_website",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a datasource using it numeric ID
     * https://www.storyblok.com/docs/api/management/datasources/update-a-datasource
     */
    @Test
    func `Update a Datasource 2`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/datasources/91")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "datasource": [
                "dimensions_attributes": [
                    [
                        "entry_value": "another_slug",
                        "name": "Another Name",
                    ],
                ],
                "name": "Labels for Website",
                "slug": "label",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}