import Foundation
import Testing
import URLSessionExtension

@Suite(.serialized) struct `MAPI: AiTranslate` {

    /**
     * An object that lists all languages available for use with the AI translation feature
     * https://www.storyblok.com/docs/api/management/ai-translate/ai-languages
     */
    @Test
    func `AI Languages`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("YOUR_OAUTH_TOKEN")))
        let request = URLRequest(storyblok: storyblok, path: "ai_languages")
        let (data, _) = try await storyblok.data(for: request)
        print(try JSONSerialization.jsonObject(with: data))
    }

}
