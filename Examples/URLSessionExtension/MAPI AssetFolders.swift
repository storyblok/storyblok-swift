import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: AssetFolders` {

    /**
     * This endpoint allows you to create a new asset folder.
     * https://www.storyblok.com/docs/api/management/asset-folders/create-an-asset-folder
     */
    @Test
    func `Create an Asset Folder`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/asset_folders/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "asset_folder": [
                "name": "Header Images",
                "parent_id": 123123,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete an asset folder by using its numeric id.
     * https://www.storyblok.com/docs/api/management/asset-folders/delete-an-asset-folder
     */
    @Test
    func `Delete an Asset Folder`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/asset_folders/41")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint returns a single, asset folder object by providing a specific numeric id.
     * https://www.storyblok.com/docs/api/management/asset-folders/retrieve-a-single-asset-folder
     */
    @Test
    func `Retrieve a Single Asset Folder`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/asset_folders/41")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of asset folder objects.
     * https://www.storyblok.com/docs/api/management/asset-folders/retrieve-multiple-asset-folders
     */
    @Test
    func `Retrieve Multiple Asset Folders`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/asset_folders/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint allows updating an existing asset folder using the numeric ID.
     * https://www.storyblok.com/docs/api/management/asset-folders/update-an-asset-folder
     */
    @Test
    func `Update an Asset Folder`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/asset_folders/414142")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "asset_folder": [
                "name": "Updated folder",
                "parent_id": 288983,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}