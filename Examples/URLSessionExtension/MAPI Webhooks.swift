import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: Webhooks` {

    /**
     * You can set some of the fields available in the webhook object, below we only list the properties in the example and the possible required fields.
     * https://www.storyblok.com/docs/api/management/webhooks/add-a-webhook
     */
    @Test
    func `Add a Webhook`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/webhook_endpoints/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "webhook_endpoint": [
                "actions": [
                    "story.published",
                ],
                "activated": true,
                "endpoint": "https://apiendpoint.com",
                "name": "Rebuild Website",
                "secret": "",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a webhook by its numeric ID.
     * https://www.storyblok.com/docs/api/management/webhooks/delete-a-webhook
     */
    @Test
    func `Delete a Webhook`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/webhook_endpoints/4573")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single webhook object by providing a specific numeric ID.
     * https://www.storyblok.com/docs/api/management/webhooks/retrieve-a-single-webhook
     */
    @Test
    func `Retrieve a Single Webhook`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/webhook_endpoints/4570")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of webhook objects
     * https://www.storyblok.com/docs/api/management/webhooks/retrieve-multiple-webhooks
     */
    @Test
    func `Retrieve Multiple Webhooks`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/webhook_endpoints/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * You can update an existing webhook field using the numeric ID.
     * https://www.storyblok.com/docs/api/management/webhooks/update-a-webhook
     */
    @Test
    func `Update a Webhook`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/webhook_endpoints/4570")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "webhook_endpoint": [
                "actions": [
                    "story.published",
                    "story.unpublished",
                ],
                "activated": true,
                "endpoint": "https://new-api-endpoint.com",
                "name": "Rebuild Website",
                "secret": "HelloSecret",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}
