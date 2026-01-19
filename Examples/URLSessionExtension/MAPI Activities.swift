import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: Activities` {

    /**
     * Returns a single activity object with a specific numeric ID. Every response contains two extra keys, one called trackable, that contains data about the changed object and the other called user that contains the user information.
     * https://www.storyblok.com/docs/api/management/activities/retrieve-a-single-activity
     */
    @Test
    func `Retrieve a Single Activity`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/activities/1234312323")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of activity objects, along with trackable and user objects. Can be filtered on date ranges and is paged.
     * https://www.storyblok.com/docs/api/management/activities/retrieve-multiple-activities
     */
    @Test
    func `Retrieve Multiple Activities`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/activities/")
        request.url!.append(queryItems: [
            URLQueryItem(name: "created_at_gte", value: "2018-12-14"),
            URLQueryItem(name: "created_at_lte", value: "2018-12-18")
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}