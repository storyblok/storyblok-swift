import Foundation
import Testing
import URLSessionExtension

@Suite struct `MAPI: BranchDeployments` {

    /**
     * Once you have set your Pipelines (via the Storyblok App or the Management API), you can start to trigger the deployment. The deployment could be triggered via Storyblok UI in the Content section by selecting the pipeline in the Pipelines dropdown.
     * https://www.storyblok.com/docs/api/management/branch-deployments/create-a-branch-deployment
     */
    @Test
    func `Create a Branch Deployment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/deployments/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "branch_id": 1,
            "release_uuids": [
                "1234-4567",
                "1234-4568",
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}