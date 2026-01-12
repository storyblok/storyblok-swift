import Foundation
import Testing

@Suite struct `MAPI: Collaborators` {

    /**
     * Add collaborators with specific roles and permissions available in the collaborator object
     * https://www.storyblok.com/docs/api/management/collaborators/add-a-collaborator
     */
    @Test
    func `Add a Collaborator`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/collaborators/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "allow_multiple_roles_creation": false,
            "email": "api.test@storyblok.com",
            "permissions": [ ],
            "role": "admin",
            "space_role_id": nil,
            "space_role_ids": [ ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Add collaborators with specific roles and permissions available in the collaborator object
     * https://www.storyblok.com/docs/api/management/collaborators/add-a-collaborator
     */
    @Test
    func `Add a Collaborator 2`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/collaborators/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "allow_multiple_roles_creation": false,
            "email": "api.test@storyblok.com",
            "permissions": [ ],
            "role": "62454",
            "space_role_id": 62454,
            "space_role_ids": [ ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Add collaborators with specific roles and permissions available in the collaborator object
     * https://www.storyblok.com/docs/api/management/collaborators/add-a-collaborator
     */
    @Test
    func `Add a Collaborator 3`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/collaborators/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "allow_multiple_roles_creation": true,
            "email": "api.test@storyblok.com",
            "permissions": [ ],
            "role": "multi",
            "space_role_id": nil,
            "space_role_ids": [
                62454,
                123123,
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Add a user with SSO using the 
     * https://www.storyblok.com/docs/api/management/collaborators/add-a-user-with-sso
     */
    @Test
    func `Add a User with SSO`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/collaborators/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "collaborator": [
                "email": "api@storyblok.com",
                "role": "editor",
                "space_role_id": 18,
                "sso_id": "123456789",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a collaborator using their 
     * https://www.storyblok.com/docs/api/management/collaborators/delete-a-collaborator
     */
    @Test
    func `Delete a Collaborator`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/collaborators/2362")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a paginated array of collaborator objects
     * https://www.storyblok.com/docs/api/management/collaborators/retrieve-multiple-collaborators
     */
    @Test
    func `Retrieve Multiple Collaborators`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/collaborators/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a collaborator using all fields available in the collaborator object
     * https://www.storyblok.com/docs/api/management/collaborators/update-a-collaborator-roles-and-permissions
     */
    @Test
    func `Update a Collaborator Roles and Permissions`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/collaborators/2362")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "collaborator": [
                "role": 49707,
                "space_role_id": 49707,
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}
