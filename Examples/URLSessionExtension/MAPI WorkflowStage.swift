import Foundation
import Testing

@Suite struct `MAPI: WorkflowStage` {

    /**
     * This endpoint allows you to create a workflow stage.
     * https://www.storyblok.com/docs/api/management/workflow-stage/create-a-workflow-stage
     */
    @Test
    func `Create a Workflow Stage`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/space_id/workflow_stages")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "workflow_stage": [
                "after_publish_id": 561398,
                "allow_admin_change": true,
                "allow_admin_publish": true,
                "allow_all_stages": false,
                "allow_all_users": false,
                "allow_editor_change": false,
                "allow_publish": true,
                "color": "#2d3v22",
                "is_default": false,
                "name": "testb",
                "position": 3,
                "space_role_ids": [
                    111111,
                    222222,
                ],
                "user_ids": [
                    123123,
                ],
                "workflow_id": 43112,
                "workflow_stage_ids": [
                    561398,
                ],
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete a workflow stage using its numeric ID.
     * https://www.storyblok.com/docs/api/management/workflow-stage/delete-a-workflow-stage
     */
    @Test
    func `Delete a Workflow Stage`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/workflow_stages/18")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "DELETE"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns a single workflow stage object by providing a specific numeric id.
     * https://www.storyblok.com/docs/api/management/workflow-stage/retrieve-a-single-workflow-stage
     */
    @Test
    func `Retrieve a Single Workflow Stage`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/workflow_stages/18")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of workflow stages.
     * https://www.storyblok.com/docs/api/management/workflow-stage/retrieve-multiple-workflow-stages
     */
    @Test
    func `Retrieve Multiple Workflow Stages`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/workflow_stages/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * This endpoint can be used to update a workflow stage using the numeric ID.
     * https://www.storyblok.com/docs/api/management/workflow-stage/update-a-workflow-stage
     */
    @Test
    func `Update a Workflow Stage`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/space_id/workflow_stages/18")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "workflow_stage": [
                "after_publish_id": 561398,
                "allow_admin_change": true,
                "allow_admin_publish": false,
                "allow_all_stages": false,
                "allow_all_users": false,
                "allow_editor_change": true,
                "allow_publish": true,
                "color": "#fff",
                "is_default": true,
                "name": "an updated stage ",
                "position": 2,
                "space_role_ids": [
                    232323,
                ],
                "user_ids": [
                    343434,
                ],
                "workflow_stage_ids": [
                    561398,
                ],
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Create a workflow stage change. It is important to pass a story ID along with the object.
     * https://www.storyblok.com/docs/api/management/workflow-stage-changes/create-a-workflow-stage-change
     */
    @Test
    func `Create a Workflow Stage Change`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/space_id/workflow_stage_changes/")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "workflow_stage_change": [
                "story_id": 123,
                "workflow_stage_id": 123,
            ],
        ])
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of workflow stage change objects.
     * https://www.storyblok.com/docs/api/management/workflow-stage-changes/retrieve-multiple-workflow-stage-changes
     */
    @Test
    func `Retrieve Multiple Workflow Stage Changes`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/spaces/288868932106293/workflow_stage_changes?with_story=123")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}