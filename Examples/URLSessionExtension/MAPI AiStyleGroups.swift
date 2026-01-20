import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: AiStyleGroups` {

    /**
     * Creates a new AI style group for the organization
     * https://www.storyblok.com/docs/api/management/ai-style-groups/organizations/create-ai-style-group-organization
     */
    @Test
    func `Create an AI Style Group in an Organization`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "orgs/me/ai_style_groups")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ai_output_rule_ids": [
                123456789012347,
                123456789012348,
            ],
            "ai_style_group": [
                "description": "Organization-level guidelines for all content",
                "name": "Company-wide Style Guide",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete an AI style group from the organization
     * https://www.storyblok.com/docs/api/management/ai-style-groups/organizations/delete-ai-style-group-organization
     */
    @Test
    func `Delete an AI Style Group from an Organization`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "orgs/me/ai_style_groups/123456")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve AI style groups currently set as default for the organization
     * https://www.storyblok.com/docs/api/management/ai-style-groups/organizations/retrieve-default-ai-style-groups-organization
     */
    @Test
    func `Retrieve Default AI Style Groups in an Organization`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "orgs/me/default_ai_style_groups")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve all AI style groups available in the specified organization
     * https://www.storyblok.com/docs/api/management/ai-style-groups/organizations/retrieve-multiple-ai-style-groups-organization
     */
    @Test
    func `Retrieve Multiple AI Style Groups in an Organization`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "orgs/me/ai_style_groups")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieves a single AI style group available in the specified organization
     * https://www.storyblok.com/docs/api/management/ai-style-groups/organizations/retrieve-single-ai-style-group-organization
     */
    @Test
    func `Retrieve a Single AI Style Group in an Organization`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "orgs/me/ai_style_groups/123456")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Set the default AI style groups for the specified organization
     * https://www.storyblok.com/docs/api/management/ai-style-groups/organizations/set-default-ai-style-groups-organization
     */
    @Test
    func `Set Default AI Style Groups for an Organization`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "orgs/me/default_ai_style_groups")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ai_style_group_ids": [
                123456,
                123457,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update an existing AI style group in the specified organization
     * https://www.storyblok.com/docs/api/management/ai-style-groups/organizations/update-ai-style-group-organization
     */
    @Test
    func `Update an AI Style Group in an Organization`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "orgs/me/ai_style_groups/123456")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ai_output_rule_ids": [
                123456789012349,
                123456789012350,
            ],
            "ai_style_group": [
                "description": "Updated organization-level guidelines",
                "name": "Updated Company Style Guide",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Create a new AI style group in the specified space
     * https://www.storyblok.com/docs/api/management/ai-style-groups/spaces/create-ai-style-group-space
     */
    @Test
    func `Create an AI Style Group in a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/ai_style_groups")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ai_output_rule_ids": [
                123456789012345,
                123456789012346,
            ],
            "ai_style_group": [
                "description": "Brand guidelines for marketing content creation",
                "name": "Marketing Style Guide",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete an AI style group from the specified space
     * https://www.storyblok.com/docs/api/management/ai-style-groups/spaces/delete-ai-style-group-space
     */
    @Test
    func `Delete an AI Style Group from a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/ai_style_groups/67499417567240")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve AI style groups currently set as default for the space
     * https://www.storyblok.com/docs/api/management/ai-style-groups/spaces/retrieve-default-ai-style-groups-space
     */
    @Test
    func `Retrieve Default AI Style Groups in a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/default_ai_style_groups")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve all AI style groups available in the specified space, including space-specific groups and inherited organization groups.
     * https://www.storyblok.com/docs/api/management/ai-style-groups/spaces/retrieve-multiple-ai-style-groups-space
     */
    @Test
    func `Retrieve Multiple AI Style Groups in a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/ai_style_groups")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a single AI style group available in the specified space
     * https://www.storyblok.com/docs/api/management/ai-style-groups/spaces/retrieve-single-ai-style-group-space
     */
    @Test
    func `Retrieve a Single AI Style Group in a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/ai_style_groups/67499417567240")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Set the default AI style groups for the specified space
     * https://www.storyblok.com/docs/api/management/ai-style-groups/spaces/set-default-ai-style-groups-space
     */
    @Test
    func `Set Default AI Style Groups for a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/default_ai_style_groups")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ai_style_group_ids": [
                68844418605065,
                68844418605067,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update an existing AI style group in the specified space
     * https://www.storyblok.com/docs/api/management/ai-style-groups/spaces/update-ai-style-group-space
     */
    @Test
    func `Update an AI Style Group in a Space`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/ai_style_groups/67499417567240")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ai_output_rule_ids": [
                123456789012345,
                123456789012348,
            ],
            "ai_style_group": [
                "description": "Updated brand guidelines for marketing content creation",
                "name": "Updated Marketing Style Guide",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}