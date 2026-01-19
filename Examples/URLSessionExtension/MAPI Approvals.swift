import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: Approvals` {

    /**
     * 
     * https://www.storyblok.com/docs/api/management/approvals/create-approval
     */
    @Test
    func `Create Approval`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/approvals/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "approval": [
                "approver_id": 1028,
                "story_id": 1066,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * The Approval feature mentioned is exclusive to Storyblok v1 and discontinued in v2.
     * https://www.storyblok.com/docs/api/management/approvals/create-release-approval
     */
    @Test
    func `Create Release Approval`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/approvals/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "approval": [
                "approver_id": 1030,
                "story_id": 1067,
            ],
            "release_id": 16,
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete an approval by using its numeric id.
     * https://www.storyblok.com/docs/api/management/approvals/delete-an-approval
     */
    @Test
    func `Delete an Approval`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/approvals/5405")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single approval object with a specific numeric id.
     * https://www.storyblok.com/docs/api/management/approvals/retrieve-a-single-approval
     */
    @Test
    func `Retrieve a Single Approval`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/approvals/5405")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of approval objects. This endpoint can be filtered on the approver and is paged.
     * https://www.storyblok.com/docs/api/management/approvals/retrieve-multiple-approvals
     */
    @Test
    func `Retrieve Multiple Approvals`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/approvals")
        request.url!.append(queryItems: [
            URLQueryItem(name: "approver", value: "1028")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}