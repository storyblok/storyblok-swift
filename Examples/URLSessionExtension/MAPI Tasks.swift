import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: Tasks` {

    /**
     * This endpoint creates a new task.
     * https://www.storyblok.com/docs/api/management/tasks/create-a-task
     */
    @Test
    func `Create a Task`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tasks/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "task": [
                "name": "My Task Name",
                "task_type": "webhook",
                "webhook_url": "https://www.storyblok.com",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a task using the numeric ID.
     * https://www.storyblok.com/docs/api/management/tasks/delete-a-task
     */
    @Test
    func `Delete a Task`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tasks/124")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single task object with a specific numeric id.
     * https://www.storyblok.com/docs/api/management/tasks/retrieve-a-single-task
     */
    @Test
    func `Retrieve a Single Task`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tasks/124")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of task objects. This endpoint is paged.
     * https://www.storyblok.com/docs/api/management/tasks/retrieve-multiple-tasks
     */
    @Test
    func `Retrieve Multiple Tasks`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tasks/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint can be used to update tasks.
     * https://www.storyblok.com/docs/api/management/tasks/update-a-task
     */
    @Test
    func `Update a Task`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/tasks/124")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "task": [
                "name": "My Updated Task Name",
                "task_type": "webhook",
                "webhook_url": "https://www.storyblok.com",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}