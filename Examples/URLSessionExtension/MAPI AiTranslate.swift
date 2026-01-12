import Foundation
import Testing

@Suite struct `MAPI: AiTranslate` {

    /**
     * An object that lists all languages available for use with the AI translation feature
     * https://www.storyblok.com/docs/api/management/ai-translate/ai-languages
     */
    @Test
    func `AI Languages`() async throws {
        var request = URLRequest(url: URL(string: "https://mapi.storyblok.com/v1/ai_languages")!)
        request.setValue("YOUR_OAUTH_TOKEN", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let (data, _) = try await URLSession.shared.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}