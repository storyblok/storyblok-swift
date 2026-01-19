import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: Assets` {

    /**
     * This endpoint allows moving multiple assets using their IDs to a specific folder.
     * https://www.storyblok.com/docs/api/management/assets/bulk-moving-of-assets
     */
    @Test
    func `Bulk Moving of Assets`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/assets/bulk_update")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "asset_folder_id": 299783,
            "ids": [
                15904978,
                15878980,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * To bulk restoration of deleted assets, pass bulk_restore after assets in the endpoint. Inside of the array from the payload should contain the asset IDs that you want to restore.
     * https://www.storyblok.com/docs/api/management/assets/bulk-restoration-of-deleted-assets
     */
    @Test
    func `Bulk Restoration of Deleted Assets`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/assets/bulk_restore")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ids": [
                13941914,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete an asset by using its numeric id.
     * https://www.storyblok.com/docs/api/management/assets/delete-an-asset
     */
    @Test
    func `Delete an Asset`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/assets/14")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete multiple assets by using their numeric IDs.
     * https://www.storyblok.com/docs/api/management/assets/delete-multiple-assets
     */
    @Test
    func `Delete Multiple Assets`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/assets/bulk_destroy")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "ids": [
                20142579,
                20142580,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Validates an uploaded asset and returns a minimal asset object. See upload and replace assets for further information.
     * https://www.storyblok.com/docs/api/management/assets/finish-upload
     */
    @Test
    func `Finish Upload`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/assets/89062407031871/finish_upload")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a signed response to be used to upload the asset. See upload and replace assets for further information.
     * https://www.storyblok.com/docs/api/management/assets/get-signed-response
     */
    @Test
    func `Get a Signed Response Object`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/assets/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "asset_folder_id": 638352,
            "filename": "123.jpg",
            "id": 89293614204583,
            "size": "",
            "validate_upload": 1,
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of asset objects. This endpoint is paginated.
     * https://www.storyblok.com/docs/api/management/assets/retrieve-multiple-assets
     */
    @Test
    func `Retrieve Multiple Assets`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/assets/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single asset object by providing a specific numeric id.
     * https://www.storyblok.com/docs/api/management/assets/retrieve-one-asset
     */
    @Test
    func `Retrieve One Asset`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/assets/14")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update an asset's metadata using its numeric ID
     * https://www.storyblok.com/docs/api/management/assets/update-asset
     */
    @Test
    func `Update Asset`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/assets/656565")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "asset_folder_id": 123123,
            "internal_tag_ids": [
                1111,
            ],
            "is_private": true,
            "locked": false,
            "meta_data": [
                "alt": "Asset alt text",
                "copyright": "Copyright text",
                "source": "Asset source",
                "title": "Asset title",
            ],
            "publish_at": "2025-05-31T11:52:00.000Z",
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}