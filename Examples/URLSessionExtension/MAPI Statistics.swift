import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: Statistics` {

    /**
     * Returns API traffic usage statistics for the organization.
     * https://www.storyblok.com/docs/api/management/statistics/retrieve-api-traffic-statistics
     */
    @Test
    func `Retrieve API Traffic Statistics`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "orgs/me/statistics/all_traffic")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns assets traffic usage statistics for the organization.
     * https://www.storyblok.com/docs/api/management/statistics/retrieve-assets-traffic-statistics
     */
    @Test
    func `Retrieve Assets Traffic Statistics`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "orgs/me/statistics/assets_traffic")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of statistics for a specific month.
     * https://www.storyblok.com/docs/api/management/statistics/retrieve-statistics-by-date
     */
    @Test
    func `Retrieve Statistics by Date`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/44203/statistics/2026-03-01")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}