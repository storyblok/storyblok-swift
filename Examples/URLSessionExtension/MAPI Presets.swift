import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: Presets` {

    /**
     * This endpoint can be used to create new presets.
     * https://www.storyblok.com/docs/api/management/presets/create-a-preset
     */
    @Test
    func `Create a Preset`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/presets/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "preset": [
                "component_id": 62,
                "name": "Teaser with filled headline",
                "preset": [
                    "headline": "This is a default value for the preset!",
                ],
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a preset by using its numeric id.
     * https://www.storyblok.com/docs/api/management/presets/delete-a-preset
     */
    @Test
    func `Delete a Preset`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/presets/1814")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single preset object with a specific numeric id.
     * https://www.storyblok.com/docs/api/management/presets/retrieve-a-single-preset
     */
    @Test
    func `Retrieve a Single Preset`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/presets/1814")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of preset objects.
     * https://www.storyblok.com/docs/api/management/presets/retrieve-multiple-presets
     */
    @Test
    func `Retrieve Multiple Presets`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/presets")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint can be used to update presets using the numeric ID.
     * https://www.storyblok.com/docs/api/management/presets/update-a-preset
     */
    @Test
    func `Update a Preset`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/presets/1814")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "preset": [
                "component_id": 62,
                "name": "Teaser with headline and image",
                "preset": [
                    "headline": "This is a default value for the preset!",
                    "image": "//a.storyblok.com/f/606/...",
                ],
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}
