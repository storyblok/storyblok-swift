import Foundation
import Testing

@Suite struct `MAPI: WorkflowStageChanges` {

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