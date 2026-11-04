import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: Experiments` {

    /**
     * Transition an experiment from draft or paused to running.
     * https://www.storyblok.com/docs/api/management/experiments/activate-an-experiment
     */
    @Test
    func `Activate an Experiment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/activate")
        request.url!.append(queryItems: [
            URLQueryItem(name: "end_date", value: "2026-08-20")
        ])
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [ ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Complete an experiment and select a winning variant.
     * https://www.storyblok.com/docs/api/management/experiments/complete-an-experiment-with-a-winning-variant
     */
    @Test
    func `Complete an Experiment with a Winning Variant`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/complete_with_winner")
        request.url!.append(queryItems: [
            URLQueryItem(name: "variant_id", value: "176070002762432")
        ])
        request.httpMethod = "PATCH"
        request.httpBody = try JSONSerialization.data(withJSONObject: [ ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Complete a running experiment without selecting a winning variant.
     * https://www.storyblok.com/docs/api/management/experiments/complete-an-experiment
     */
    @Test
    func `Complete an Experiment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/complete")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [ ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Map a story to an experiment variant.
     * https://www.storyblok.com/docs/api/management/experiments/create-a-story-mapping
     */
    @Test
    func `Create a Story Mapping`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/variants/1002/story_mappings")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "story_mapping": [
                "original_story_id": 176024833123843,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Create a new experiment in a space.
     * https://www.storyblok.com/docs/api/management/experiments/create-an-experiment
     */
    @Test
    func `Create an Experiment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "experiment": [
                "description": "A short description for a simple test",
                "display_name": "A simple test",
                "experiment_variants_attributes": [
                    [
                        "display_name": "Control",
                        "is_control": true,
                        "name": "control",
                        "weight": 60,
                    ],
                    [
                        "display_name": "Test",
                        "is_control": false,
                        "name": "test",
                        "weight": 40,
                    ],
                ],
                "name": "a_simple_test",
                "story_ids": [
                    176024833123843,
                ],
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Remove a story-to-variant mapping from an experiment variant.
     * https://www.storyblok.com/docs/api/management/experiments/delete-a-story-mapping
     */
    @Test
    func `Delete a Story Mapping`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/variants/1002/story_mappings/176024833123843")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Delete an experiment.
     * https://www.storyblok.com/docs/api/management/experiments/delete-an-experiment
     */
    @Test
    func `Delete an Experiment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Link a story to an experiment.
     * https://www.storyblok.com/docs/api/management/experiments/link-a-story
     */
    @Test
    func `Link a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/stories")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "experiment_story": [
                "story_id": 176024833123843,
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Pause a running experiment.
     * https://www.storyblok.com/docs/api/management/experiments/pause-an-experiment
     */
    @Test
    func `Pause an Experiment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/pause")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [ ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Push results to a single experiment.
     * https://www.storyblok.com/docs/api/management/experiments/push-experiment-results
     */
    @Test
    func `Push Experiment Results`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/results")
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "charts": [
                [
                    "body": "Variant A shows 95% confidence of improvement.",
                    "kind": "bar",
                    "labels": [
                        "Control",
                        "Variant A",
                    ],
                    "series": [
                        [
                            "data": [
                                0.12,
                                0.15,
                            ],
                            "label": "Conversion rate",
                        ],
                    ],
                    "title": "Conversion Rate",
                    "xLabel": "Variant",
                    "yLabel": "Rate",
                ],
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve a single experiment by its numeric ID.
     * https://www.storyblok.com/docs/api/management/experiments/retrieve-a-single-experiment
     */
    @Test
    func `Retrieve a Single Experiment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Retrieve results for a single experiment.
     * https://www.storyblok.com/docs/api/management/experiments/retrieve-experiment-results
     */
    @Test
    func `Retrieve Experiment Results`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/results")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Returns an array of experiments.
     * https://www.storyblok.com/docs/api/management/experiments/retrieve-multiple-experiments
     */
    @Test
    func `Retrieve Multiple Experiments`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Select a winning variant for a completed experiment.
     * https://www.storyblok.com/docs/api/management/experiments/select-a-winning-variant
     */
    @Test
    func `Select a Winning Variant`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/select_winner")
        request.url!.append(queryItems: [
            URLQueryItem(name: "variant_id", value: "176070002791237")
        ])
        request.httpMethod = "PATCH"
        request.httpBody = try JSONSerialization.data(withJSONObject: [ ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Unlink a story from an experiment.
     * https://www.storyblok.com/docs/api/management/experiments/unlink-a-story
     */
    @Test
    func `Unlink a Story`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742/stories/176024833123843")
        request.httpMethod = "DELETE"
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

    /**
     * Update an existing experiment.
     * https://www.storyblok.com/docs/api/management/experiments/update-an-experiment
     */
    @Test
    func `Update an Experiment`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .personal("YOUR_PERSONAL_ACCESS_TOKEN")))
        var request = URLRequest(storyblok: storyblok, path: "spaces/288868932106293/experiments/176070002766742")
        request.httpMethod = "PUT"
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "experiment": [
                "description": "Updated description",
                "display_name": "A simple test (updated)",
                "experiment_variants_attributes": [
                    [
                        "id": 1001,
                        "weight": 70,
                    ],
                    [
                        "id": 1002,
                        "weight": 40,
                    ],
                ],
            ],
        ])
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}