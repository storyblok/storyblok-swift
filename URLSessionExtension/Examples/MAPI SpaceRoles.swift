import Foundation
import Testing

@Suite struct `MAPI: SpaceRoles` {

    /**
     * This endpoint allows you to create a new space role.
     * https://www.storyblok.com/docs/api/management/space-roles/create-a-space-role
     */
    @Test
    func `Create a Space Role`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/space_roles/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "space_role": [
                "allowed_languages": [
                    "default",
                    "de",
                ],
                "allowed_paths": [
                    43097198,
                    48581646,
                ],
                "asset_folder_ids": [
                    56328,
                    29783,
                ],
                "branch_ids": [
                    304011,
                ],
                "component_ids": [
                    57584,
                    43743,
                    72760,
                    67535,
                ],
                "datasource_ids": [
                    2189,
                ],
                "field_permissions": [
                    "article.title",
                    "hero.image",
                ],
                "permissions": [
                    "manage_block_library",
                    "deny_component_technical_name_update",
                    "deny_component_fields_name_update",
                    "edit_image",
                    "delete_stories",
                    "deploy_stories",
                    "unpublish_stories",
                    "unpublish_folders",
                    "publish_stories",
                    "publish_folders",
                    "manage-non-translatable-fields",
                    "manage_tags",
                ],
                "readonly_field_permissions": [
                    "hero.RichText_type",
                    "hero.TextArea_type",
                ],
                "role": "Test role",
                "subtitle": "desc",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a space role using its numeric id.
     * https://www.storyblok.com/docs/api/management/space-roles/delete-a-space-role
     */
    @Test
    func `Delete a Space Role`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/space_roles/18")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single, space role object by providing a specific numeric id.
     * https://www.storyblok.com/docs/api/management/space-roles/retrieve-a-single-space-role
     */
    @Test
    func `Retrieve a Single Space Role`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/space_roles/18")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of space role objects.
     * https://www.storyblok.com/docs/api/management/space-roles/retrieve-multiple-space-roles
     */
    @Test
    func `Retrieve Multiple Space Roles`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/space_roles/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows you to update a space role by the numeric ID.
     * https://www.storyblok.com/docs/api/management/space-roles/update-a-space-role
     */
    @Test
    func `Update a Space Role`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/space_roles/18")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "space_role": [
                "allowed_languages": [
                    "de",
                ],
                "allowed_paths": [
                    430937198,
                ],
                "asset_folder_ids": [
                    563628,
                ],
                "branch_ids": [
                    30403,
                ],
                "component_ids": [
                    5758347,
                ],
                "datasource_ids": [
                    218499,
                ],
                "field_permissions": [
                    "a-new-blok.title",
                    "A new comppppp.Text_type",
                    "a-new-blok.image",
                    "page.body",
                ],
                "permissions": [
                    "manage_block_library",
                    "deny_component_technical_name_update",
                    "deny_component_fields_name_update",
                    "edit_image",
                    "delete_stories",
                    "deploy_stories",
                    "unpublish_stories",
                    "unpublish_folders",
                    "publish_stories",
                    "publish_folders",
                    "manage-non-translatable-fields",
                ],
                "readonly_field_permissions": [
                    "A new comppppp.RichText_type",
                    "A new comppppp.TextArea_type",
                    "page.body",
                ],
                "role": "Another new space role",
                "subtitle": "new desc",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}