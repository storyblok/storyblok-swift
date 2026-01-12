import Foundation
import Testing

@Suite struct `MAPI: Activities` {

    /**
     * Returns a single activity object with a specific numeric ID. Every response contains two extra keys, one called trackable, that contains data about the changed object and the other called user that contains the user information.
     * https://www.storyblok.com/docs/api/management/activities/retrieve-a-single-activity
     */
    @Test
    func `Retrieve a Single Activity`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/activities/1234312323")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of activity objects, along with trackable and user objects. Can be filtered on date ranges and is paged.
     * https://www.storyblok.com/docs/api/management/activities/retrieve-multiple-activities
     */
    @Test
    func `Retrieve Multiple Activities`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/activities/?created_at_gte=2018-12-14&created_at_lte=2018-12-18")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}