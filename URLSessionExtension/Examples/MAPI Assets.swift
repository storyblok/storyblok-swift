import Foundation
import Testing

@Suite struct `MAPI: Assets` {

    /**
     * This endpoint allows moving multiple assets using their IDs to a specific folder.
     * https://www.storyblok.com/docs/api/management/assets/bulk-moving-of-assets
     */
    @Test
    func `Bulk Moving of Assets`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/assets/bulk_update")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "asset_folder_id": 299783,
            "ids": [
                15904978,
                15878980,
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * To bulk restoration of deleted assets, pass bulk_restore after assets in the endpoint. Inside of the array from the payload should contain the asset IDs that you want to restore.
     * https://www.storyblok.com/docs/api/management/assets/bulk-restoration-of-deleted-assets
     */
    @Test
    func `Bulk Restoration of Deleted Assets`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/assets/bulk_restore")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ids": [
                13941914,
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete an asset by using its numeric id.
     * https://www.storyblok.com/docs/api/management/assets/delete-an-asset
     */
    @Test
    func `Delete an Asset`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/assets/14")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete multiple assets by using their numeric IDs.
     * https://www.storyblok.com/docs/api/management/assets/delete-multiple-assets
     */
    @Test
    func `Delete Multiple Assets`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/assets/bulk_destroy")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ids": [
                20142579,
                20142580,
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Validates an uploaded asset and returns a minimal asset object. See upload and replace assets for further information.
     * https://www.storyblok.com/docs/api/management/assets/finish-upload
     */
    @Test
    func `Finish Upload`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/assets/89062407031871/finish_upload")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a signed response to be used to upload the asset. See upload and replace assets for further information.
     * https://www.storyblok.com/docs/api/management/assets/get-signed-response
     */
    @Test
    func `Get a Signed Response Object`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/assets/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "asset_folder_id": 638352,
            "filename": "123.jpg",
            "id": 89293614204583,
            "size": "",
            "validate_upload": 1,
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of asset objects. This endpoint is paginated.
     * https://www.storyblok.com/docs/api/management/assets/retrieve-multiple-assets
     */
    @Test
    func `Retrieve Multiple Assets`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/assets/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single asset object by providing a specific numeric id.
     * https://www.storyblok.com/docs/api/management/assets/retrieve-one-asset
     */
    @Test
    func `Retrieve One Asset`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/assets/14")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update an asset using the the numeric ID of the asset.
     * https://www.storyblok.com/docs/api/management/assets/update-asset
     */
    @Test
    func `Update Asset`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/assets/656565")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "asset_folder_id": 123123,
            "internal_tag_ids": [
                1111,
            ],
            "is_private": true,
            "locked": false,
            "meta_data": [
                "alt": "Asset ALT",
                "copyright": "Custom Text",
                "source": "Asset Source",
                "title": "Asset Title",
            ],
            "publish_at": "2024-05-31T11:52:00.000Z",
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}