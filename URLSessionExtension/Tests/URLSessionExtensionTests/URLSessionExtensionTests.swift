import Foundation
import Testing
import Mocker
@testable import URLSessionExtension

@Suite(.serialized) struct URLSessionExtensionTests {

    let mockConfiguration = URLSessionConfiguration.default
    
    init() {
        mockConfiguration.protocolClasses = [MockingURLProtocol.self]
    }
    
    @Test func `adds json content type header on put and post requests`() async throws {
        let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth(token: "mock-api-key")), configuration: mockConfiguration)
        var request = URLRequest(storyblok: storyblok, path: "spaces/123/stories/1234")
        var mock = Mock(url: request.url!, statusCode: 200, data: [.post: Data(), .put: Data()])
        mock.onRequestHandler = OnRequestHandler(requestCallback: { request in
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        })
        mock.register()
        request.httpMethod = "PUT"
        _ = try await storyblok.data(for: request)
        request.httpMethod = "POST"
        _ = try await storyblok.data(for: request)
    }
    
    @Test func `requests are throttled according to the specified value in requestsPerSecond`() async throws {
        let storyblok = URLSession(
            storyblok: .mapi(accessToken: .personal(token: "mock-api-key"), requestsPerSecond: 1),
            configuration: mockConfiguration
        )
        let request = URLRequest(storyblok: storyblok, path: "spaces/123/stories/1234")
        let mock = Mock(request: request, statusCode: 200)
        mock.register()
        storyblok.dataTask(with: request).resume()
        let duration = try await ContinuousClock.continuous.measure {
            _ = try await storyblok.data(for: request)
        }
        //allow 15 millisecond error
        #expect(duration > .seconds(1) - .milliseconds(15))
    }
    
    @Test func `failOnErrorResponse(.recoverable) throws only on server error and 429 (too many requests) status codes`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "mock-api-key"), configuration: mockConfiguration)
        let request = URLRequest(storyblok: storyblok, path: "stories/mock-slug")
        let mock = Mock(request: request, statusCode: 404)
        mock.register()
        _ = try await storyblok.dataTaskPublisher(for: request)
            .failOnErrorResponse(.recoverable)
            .values
            .first { _ in true }
        await #expect(throws: Api.ResponseError.self) {
            let mock = Mock(request: request, statusCode: 501)
            mock.register()
            _ = try await storyblok.dataTaskPublisher(for: request)
                .failOnErrorResponse(.recoverable)
                .values
                .first { _ in true }
        }
        await #expect(throws: Api.ResponseError.self) {
            let mock = Mock(request: request, statusCode: 429)
            mock.register()
            _ = try await storyblok.dataTaskPublisher(for: request)
                .failOnErrorResponse(.recoverable)
                .values
                .first { _ in true }
        }
    }
    
    @Test func `failOnErrorResponse(.all) throws on client error status codes`() async throws {
        let storyblok = URLSession(storyblok: .cdn(accessToken: "mock-api-key"), configuration: mockConfiguration)
        let request = URLRequest(storyblok: storyblok, path: "stories/mock-slug")
        let mock = Mock(request: request, statusCode: 401)
        mock.register()
        await #expect(throws: Api.ResponseError.self) {
            _ = try await storyblok.dataTaskPublisher(for: request)
                .failOnErrorResponse(.all)
                .values
                .first { _ in true }
        }
    }

    @Test func `on server error or 429 (too many requests) status codes subsequent requests are subject to an exponential backoff`() async throws {
        let storyblok = URLSession(
            storyblok: .mapi(accessToken: .personal(token: "mock-api-key")),
            configuration: mockConfiguration
        )
        
        let failingRequest = URLRequest(storyblok: storyblok, path: "spaces/123/stories/1234")
        let failingMock = Mock(request: failingRequest, statusCode: 429)
        failingMock.register()
        
        _ = try await storyblok.data(for: failingRequest)
        
        let secondRequestDuration = try await ContinuousClock.continuous.measure {
            _ = try await storyblok.data(for: failingRequest)
        }
        //subsequent request subject to backoff
        #expect(secondRequestDuration > .seconds(2) - .milliseconds(15))
        
        let succeedingRequest = URLRequest(storyblok: storyblok, path: "spaces/123/stories/1234")
        let succeedingMock = Mock(request: succeedingRequest, statusCode: 200)
        succeedingMock.register()

        let thirdRequestDuration = try await ContinuousClock.continuous.measure {
            _ = try await storyblok.data(for: succeedingRequest)
        }
        //backoff grows exponentially
        #expect(thirdRequestDuration > .seconds(4) - .milliseconds(15))
        
        let fourthRequestDuration = try await ContinuousClock.continuous.measure {
            _ = try await storyblok.data(for: succeedingRequest)
        }
        //no backoff after sucessful request
        #expect(fourthRequestDuration < .seconds(1.0/6) + .milliseconds(15))
    }
    
    @Test func `retried requests are also subject to an exponential backoff`() async throws {
        let storyblok = URLSession(
            storyblok: .mapi(accessToken: .personal(token: "mock-api-key")),
            configuration: mockConfiguration
        )
        let failingRequest = URLRequest(storyblok: storyblok, path: "spaces/123/stories/1234")
        let failingMock = Mock(request: failingRequest, statusCode: 429)
        failingMock.register()
        let duration = await ContinuousClock.continuous.measure {
            await #expect(throws: Api.ResponseError.self) {
                let _ = try await storyblok.dataTaskPublisher(for: failingRequest)
                    .failOnErrorResponse(.recoverable)
                    .retry(2)
                    .values
                    .first { _ in true }
            }
        }
        //first backoff (2s) + second backoff (4s) + error (15ms)
        #expect(duration > .seconds(2) + .seconds(4) + .milliseconds(15))
    }
}
