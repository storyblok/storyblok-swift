import Foundation
import Testing

@Suite struct `MAPI: SchedulingStories` {

    /**
     * This endpoint allows you to create a new story schedule.
     * https://www.storyblok.com/docs/api/management/scheduling-stories/create-a-story-schedule
     */
    @Test
    func `Create a Story Schedule`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/story_schedulings")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "story_scheduling": [
                "language": "pt-br",
                "publish_at": "2024-07-26T06:56:00.000Z",
                "story_id": 362419485,
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a schedule by the numeric ID.
     * https://www.storyblok.com/docs/api/management/scheduling-stories/delete-a-story-schedule
     */
    @Test
    func `Delete a Story Schedule`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/story_schedulings/123/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of story schedule objects.
     * https://www.storyblok.com/docs/api/management/scheduling-stories/retrieve-multiple-story-schedules
     */
    @Test
    func `Retrieve Multiple Story Schedules`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/story_schedulings")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single schedule object by providing a specific numeric ID.
     * https://www.storyblok.com/docs/api/management/scheduling-stories/retrieve-one-story-schedule
     */
    @Test
    func `Retrieve One Story Schedule`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/story_schedulings/91")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update a publishing schedule by the numeric ID.
     * https://www.storyblok.com/docs/api/management/scheduling-stories/update-a-story-schedule
     */
    @Test
    func `Update a Story Schedule`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/story_schedulings/123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "story_scheduling": [
                "publish_at": "2024-08-26T06:56:00.000Z",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}