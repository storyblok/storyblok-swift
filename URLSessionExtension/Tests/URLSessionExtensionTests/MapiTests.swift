import Foundation
import Testing
import Mocker
@testable import URLSessionExtension

@Suite(.serialized) struct MapiTests {
    
    let mockConfiguration = URLSessionConfiguration.default
    
    init() {
        mockConfiguration.protocolClasses = [MockingURLProtocol.self]
    }
    
    @Test
    func `specifying a personal access token is added as auth header`() async throws {
        let storyblok = URLSession(
            storyblok: .mapi(
                accessToken: .personal(token: "mock-api-key"),
                region: .eu
            ),
            configuration: mockConfiguration
        )
        
        let request = URLRequest(storyblok: storyblok, path: "spaces/606/stories/369689")
        var mock = Mock(request: request, statusCode: 200)
        mock.onRequestHandler = OnRequestHandler(requestCallback: { request in
            #expect(request.url?.scheme == "https")
            #expect(request.url?.host == "mapi.storyblok.com")
            #expect(request.url?.relativePath == "/v1/spaces/606/stories/369689")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "mock-api-key")
        })
        mock.register()
        _ = try await storyblok.data(for: request)
    }
    
    @Test
    func `specifying an oauth access token is added as auth header with bearer prefix`() async throws {
        let storyblok = URLSession(
            storyblok: .mapi(
                accessToken: .oauth(token: "mock-api-key"),
                region: .eu
            ),
            configuration: mockConfiguration
        )
        
        let request = URLRequest(storyblok: storyblok, path: "spaces/606/stories/369689")
        var mock = Mock(request: request, statusCode: 200)
        mock.onRequestHandler = OnRequestHandler(requestCallback: { request in
            #expect(request.url?.scheme == "https")
            #expect(request.url?.host == "mapi.storyblok.com")
            #expect(request.url?.relativePath == "/v1/spaces/606/stories/369689")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer mock-api-key")
        })
        mock.register()
        _ = try await storyblok.data(for: request)
    }

    @Test
    func `requests per second defaults to 6`() async throws {
        let api = Api.mapi(accessToken: .oauth(token: "mock-api-key"))
        switch api {
            case .mapi(_, _, requestsPerSecond: let requestsPerSecond): #expect(requestsPerSecond == 6)
            default: Issue.record("api is not mapi")
        }
    }
}
