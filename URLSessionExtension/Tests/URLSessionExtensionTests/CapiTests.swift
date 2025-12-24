import Foundation
import Testing
import Mocker
@testable import URLSessionExtension

@Suite(.serialized) struct CapiTests {
    
    let mockConfiguration = URLSessionConfiguration.default
    
    init() {
        mockConfiguration.protocolClasses = [MockingURLProtocol.self]
    }
    
    @Test
    func `request url is correctly formed from specified region, access token and uri`() async throws {
        let storyblok = URLSession(
            storyblok: .cdn(
                accessToken: "mock-api-key",
                region: .custom(url: URL(string: "https://localhost/mock-base-url/cdn/")!),
            ),
            configuration: mockConfiguration
        )
        
        let request = URLRequest(storyblok: storyblok, path: "stories/mock-slug")
        var mock = Mock(request: request, statusCode: 200)
        mock.onRequestHandler = OnRequestHandler(requestCallback: { request in
            #expect(request.url?.scheme == "https")
            #expect(request.url?.host == "localhost")
            #expect(request.url?.relativePath == "/mock-base-url/cdn/stories/mock-slug")
            #expect(request.url!.query()!.contains("token=mock-api-key"))
        })
        mock.register()
        _ = try await storyblok.data(for: request)
    }

    @Test
    func `default query parameters set when specified in config`() async throws {
        let storyblok = URLSession(
            storyblok: .cdn(
                accessToken: "mock-api-key",
                language: "mock-language",
                fallbackLanguage: "mock-fallback-lang",
                version: .draft,
                cv: "mock-cv",
                region: .custom(url: URL(string: "https://localhost/mock-base-url/cdn/")!),
            ),
            configuration: mockConfiguration
        )

        let request = URLRequest(storyblok: storyblok, path: "stories/mock-slug")
        var mock = Mock(request: request, statusCode: 200)
        mock.onRequestHandler = OnRequestHandler(requestCallback: { request in
            let components = URLComponents(string: request.url!.absoluteString)!
            let items = components.queryItems!.reduce(into: [String: String]()) { result, item in result[item.name] = item.value }
            #expect(items["token"] == "mock-api-key")
            #expect(items["version"] == "draft")
            #expect(items["cv"] == "mock-cv")
            #expect(items["language"] == "mock-language")
            #expect(items["fallback_lang"] == "mock-fallback-lang")
        })
        mock.register()
        _ = try await storyblok.data(for: request)

    }

    @Test
    func `requests per second defaults to 1000`() async throws {
        let api = Api.cdn(accessToken: "mock-api-key")
        switch(api) {
            case .cdn(_, _, _, _, _, _, requestsPerSecond: let requestsPerSecond): #expect(requestsPerSecond == 1000)
            default: Issue.record("api is not cdn")
        }
    }

    @Test
    func `follows redirect and updates cv on 301 from cdn`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "mock-api-key"), configuration: mockConfiguration)
        let request = URLRequest(storyblok: storyblok, path: "stories/mock-slug")
        let location = request.url!.appending(queryItems: [URLQueryItem(name: "cv", value: "mock-cv")])
        let redirect = Mock(url: request.url!, statusCode: 301, data: [
            .get: "Location: \(location.absoluteString)".data(using: .utf8)!
        ])
        redirect.register()
        var mock = Mock(url: location, contentType: .json, statusCode: 200, data: [
            .get: "{\"story\": { \"content\": {}}}".data(using: .utf8)!
        ])
        mock.onRequestHandler = OnRequestHandler(requestCallback: { request in
            let components = URLComponents(string: request.url!.absoluteString)!
            let items = components.queryItems!.reduce(into: [String: String]()) { result, item in result[item.name] = item.value }
            #expect(items["cv"] == "mock-cv")
        })
        mock.register()
        let (data, _) = try await storyblok.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String : Any]
        #expect(json["story"] != nil)
        //make sure future requests use the new cv
        let components = URLComponents(string: URLRequest(storyblok: storyblok, path: "stories/mock-slug").url!.absoluteString)!
        let items = components.queryItems!.reduce(into: [String: String]()) { result, item in result[item.name] = item.value }
        #expect(items["cv"] == "mock-cv")
    }
}
