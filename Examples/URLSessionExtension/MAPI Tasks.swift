import Foundation
import Testing

@Suite struct `MAPI: Tasks` {

    /**
     * This endpoint creates a new task.
     * https://www.storyblok.com/docs/api/management/tasks/create-a-task
     */
    @Test
    func `Create a Task`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/tasks/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "task": [
                "name": "My Task Name",
                "task_type": "webhook",
                "webhook_url": "https://www.storyblok.com",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a task using the numeric ID.
     * https://www.storyblok.com/docs/api/management/tasks/delete-a-task
     */
    @Test
    func `Delete a Task`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/tasks/124")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single task object with a specific numeric id.
     * https://www.storyblok.com/docs/api/management/tasks/retrieve-a-single-task
     */
    @Test
    func `Retrieve a Single Task`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/tasks/124")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of task objects. This endpoint is paged.
     * https://www.storyblok.com/docs/api/management/tasks/retrieve-multiple-tasks
     */
    @Test
    func `Retrieve Multiple Tasks`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/tasks/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint can be used to update tasks.
     * https://www.storyblok.com/docs/api/management/tasks/update-a-task
     */
    @Test
    func `Update a Task`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/tasks/124")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "task": [
                "name": "My Updated Task Name",
                "task_type": "webhook",
                "webhook_url": "https://www.storyblok.com",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}