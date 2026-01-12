import Foundation
import Testing

@Suite struct `MAPI: Workflows` {

    /**
     * This end point creates a new workflow.
     * https://www.storyblok.com/docs/api/management/workflows/create-a-workflow
     */
    @Test
    func `Create a Workflow`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/workflows")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "workflow": [
                "content_types": [
                    "page",
                ],
                "name": "page",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a workflow using the numeric ID. The default workflow cannot be deleted.
     * https://www.storyblok.com/docs/api/management/workflows/delete-a-workflow
     */
    @Test
    func `Delete a Workflow`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/workflows/656")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Creates a new custom workflow by duplicating an existing workflow using the workflow id of the parent workflow. Duplicating a workflow keeps workflow stages the same for the new workflow.The name and content types are required and should be different.
     * https://www.storyblok.com/docs/api/management/workflows/duplicate-workflow
     */
    @Test
    func `Duplicate a Workflow`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/workflows/656/duplicate")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "workflow": [
                "content_types": [
                    "page_new",
                ],
                "name": "duplicated page",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single, workflow object by providing a specific numeric ID.
     * https://www.storyblok.com/docs/api/management/workflows/retrieve-a-single-workflow
     */
    @Test
    func `Retrieve a Single Workflow`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/workflows/656")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of all the workflow stages in a space.
     * https://www.storyblok.com/docs/api/management/workflows/retrieve-multiple-workflows
     */
    @Test
    func `Retrieve Multiple Workflows`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/workflows")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint can be used to update a workflow using its numeric ID.
     * https://www.storyblok.com/docs/api/management/workflows/update-a-workflow
     */
    @Test
    func `Update a Workflow`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/workflows/656")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "workflow": [
                "content_types": [
                    "page",
                    "teaser",
                ],
                "name": "updated_name",
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}