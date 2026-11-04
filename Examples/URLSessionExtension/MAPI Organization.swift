import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: Organization` {

    /**
     * Returns the organization object for the currently authenticated user, including users, spaces, invitations, and pricing plan details.
     * https://www.storyblok.com/docs/api/management/organization/retrieve-current-organization
     */
    @Test
    func `Retrieve Current Organization`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "orgs/me")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}