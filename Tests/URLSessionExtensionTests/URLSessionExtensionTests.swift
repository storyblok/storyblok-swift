import Foundation
import Logging
import Testing
import Mocker
@testable import URLSessionExtension

@Suite(.serialized) struct URLSessionExtensionTests: TestTrait {

    static let ensureTraceLogging: () = {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .trace
            return handler
        }
    }()

    @Suite(.serialized)
    class Common {
        
        let mockConfiguration = URLSessionConfiguration.default
        
        init() {
            ensureTraceLogging
            mockConfiguration.protocolClasses = [MockingURLProtocol.self]
        }
        
        deinit {
            Mocker.removeAll()
        }
        
        @Test func `adds json content type header on put and post requests`() async throws {
            let storyblok = URLSession(storyblok: .mapi(accessToken: .oauth("mock-api-key")), configuration: mockConfiguration)
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
                storyblok: .mapi(accessToken: .personal("mock-api-key"), requestsPerSecond: 1),
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
                storyblok: .mapi(accessToken: .personal("mock-api-key")),
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
            //no backoff after successful request
            #expect(fourthRequestDuration < .seconds(2) - .milliseconds(15))
        }
        
        @Test func `a cache-only request that misses does not trigger a backoff`() async throws {
            let storyblok = URLSession(
                storyblok: .cdn(accessToken: "mock-api-key"),
                configuration: mockConfiguration
            )

            // No mock registered and nothing cached: the lookup completes without a response, like
            // the cache probe `StoryblokClient.story()` issues ahead of every fetch.
            let probe = URLRequest(storyblok: storyblok, path: "stories/never-cached", cachePolicy: .returnCacheDataDontLoad)
            _ = try? await storyblok.data(for: probe)

            let request = URLRequest(storyblok: storyblok, path: "stories/mock-slug")
            let mock = Mock(request: request, statusCode: 200)
            mock.register()

            let duration = try await ContinuousClock.continuous.measure {
                _ = try await storyblok.data(for: request)
            }
            //a server failure would have delayed this by at least 2s
            #expect(duration < .seconds(1))
        }

        @Test func `retried requests are also subject to an exponential backoff`() async throws {
            let storyblok = URLSession(
                storyblok: .mapi(accessToken: .personal("mock-api-key")),
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
    
    @Suite(.serialized)
    class Capi {
        
        let mockConfiguration = URLSessionConfiguration.default
        
        init() {
            ensureTraceLogging
            mockConfiguration.protocolClasses = [MockingURLProtocol.self]
        }
        
        deinit {
            Mocker.removeAll()
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
        func `a session's own delegate still receives what the wrapper in front of it does not handle`() async throws {
            let spy = SpyDelegate()
            let counting = CountingWrapper(delegate: spy)
            let session = URLSession(
                storyblok: .cdn(accessToken: "mock-api-key", cv: "mock-cv"),
                configuration: mockConfiguration,
                delegate: counting,
                delegateQueue: nil
            )
            let request = URLRequest(storyblok: session, path: "stories/mock-slug")
            Mock(request: request, contentType: .json, statusCode: 200, data: "{}".data(using: .utf8)!).register()
            _ = try await session.data(for: request)

            #expect(counting.tasks == 1, "the wrapper sees callbacks")
            #expect(spy.tasks == 1, "and passes them on to the delegate behind it")
            #expect(session.delegate!.responds(to: #selector(URLSessionTaskDelegate.urlSession(_:task:didCompleteWithError:))))
            #expect(!session.delegate!.responds(to: #selector(URLSessionDownloadDelegate.urlSession(_:downloadTask:didFinishDownloadingTo:))))
        }

        @Test
        func `a callback no wrapper implements is forwarded by the runtime`() {
            //neither Storyblok nor the wrapper implements didCompleteWithError, so arriving at the spy means the
            //message was re-sent down the chain without either class naming it
            let spy = SpyDelegate()
            let session = URLSession(
                storyblok: .cdn(accessToken: "mock-api-key"),
                configuration: mockConfiguration,
                delegate: CountingWrapper(delegate: spy),
                delegateQueue: nil
            )
            let task = session.dataTask(with: URL(string: "https://api.storyblok.com/v2/cdn/stories/mock-slug")!)
            defer { session.invalidateAndCancel() }

            (session.delegate as! any URLSessionTaskDelegate).urlSession?(session, task: task, didCompleteWithError: nil)

            #expect(spy.completions == 1)
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
        
        @Test
        func `subsequent requests for the same resource will be served from the cache`() async throws {
            var storyblok = URLSession(storyblok: .cdn(accessToken: "mock-api-key", cv: "mock-cv"), configuration: mockConfiguration)
            var request = URLRequest(storyblok: storyblok, path: "stories/mock-slug")
            let mock = Mock(
                request: request,
                cacheStoragePolicy: .allowedInMemoryOnly,
                contentType: .json,
                statusCode: 200,
                data: "{\"story\": { \"content\": {}}}".data(using: .utf8)!,
                additionalHeaders: ["Cache-Control" : "max-age=0, public, s-maxage=604800"]
            )
            mock.register()
            
            for _ in 0..<2 {
                let (data, _) = try await storyblok.data(for: request)
                let json = try JSONSerialization.jsonObject(with: data) as! [String : Any]
                #expect(json["story"] != nil)
                let location = request.url!.absoluteString
                Mocker.ignore(request.url!)
                storyblok = URLSession(storyblok: .cdn(accessToken: "mock-api-key"), configuration: mockConfiguration)
                request = URLRequest(storyblok: storyblok, path: "stories/mock-slug")
                let redirect = Mock(url: request.url!, statusCode: 301, data: [.get: "Location: \(location)".data(using: .utf8)!])
                redirect.register()
            }
        }

        @Test
        func `requests served from the cache are not subject to delays`() async throws {
            let storyblok = URLSession(
                storyblok: .cdn(
                    accessToken: "mock-api-key",
                    cv: "mock-cv",
                    requestsPerSecond: 1
                ),
                configuration: mockConfiguration
            )
            let request = URLRequest(storyblok: storyblok, path: "stories/mock-slug")
            let mock = Mock(
                request: request,
                cacheStoragePolicy: .allowedInMemoryOnly,
                contentType: .json,
                statusCode: 200,
                data: "{\"story\": { \"content\": {}}}".data(using: .utf8)!,
                additionalHeaders: ["Cache-Control" : "max-age=0, public, s-maxage=604800"]
            )
            mock.register()

            let duration = try await ContinuousClock.continuous.measure {
                for _ in 0..<2 {
                    let (data, _) = try await storyblok.data(for: request)
                    let json = try JSONSerialization.jsonObject(with: data) as! [String : Any]
                    #expect(json["story"] != nil)
                    Mocker.ignore(request.url!)
                }
            }
            #expect(duration < .seconds(1) - .milliseconds(15))
        }

        @Test
        func `requests for draft resources are not served from the cache`() async throws {
            let storyblok = URLSession(storyblok: .cdn(accessToken: "mock-api-key", version: .draft, cv: "mock-cv"), configuration: mockConfiguration)
            let request = URLRequest(storyblok: storyblok, path: "stories/mock-slug")
            let mock = Mock(
                request: request,
                cacheStoragePolicy: .allowedInMemoryOnly,
                contentType: .json,
                statusCode: 200,
                data: "{\"story\": { \"content\": {}}}".data(using: .utf8)!,
                additionalHeaders: ["Cache-Control" : "max-age=0, private, must-revalidate"]
            )
            mock.register()

            let (data, _) = try await storyblok.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as! [String : Any]
            #expect(json["story"] != nil)

            Mocker.ignore(request.url!)

            let (cachedData, _) = try await storyblok.data(for: request)
            let cachedJson = try JSONSerialization.jsonObject(with: cachedData) as! [String : Any]
            #expect(cachedJson["story"] == nil)
        }
    }
    
    @Suite(.serialized)
    class Mapi {
        
        let mockConfiguration = URLSessionConfiguration.default
        
        init() {
            ensureTraceLogging
            mockConfiguration.protocolClasses = [MockingURLProtocol.self]
        }
        
        deinit {
            Mocker.removeAll()
        }
        
        @Test
        func `specifying a personal access token is added as auth header`() async throws {
            let storyblok = URLSession(
                storyblok: .mapi(
                    accessToken: .personal("mock-api-key"),
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
                    accessToken: .oauth("mock-api-key"),
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
            let api = Api.mapi(accessToken: .oauth("mock-api-key"))
            switch api {
                case .mapi(_, _, requestsPerSecond: let requestsPerSecond): #expect(requestsPerSecond == 6)
                default: Issue.record("api is not mapi")
            }
        }
    }

}

final class SpyDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    var tasks = 0
    var completions = 0
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) { tasks += 1 }
    //implemented by nothing in the chain above it, so it can only arrive by forwarding
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) { completions += 1 }
}

final class CountingWrapper: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    let delegate: (any URLSessionDelegate)?
    var tasks = 0
    init(delegate: (any URLSessionDelegate)?) { self.delegate = delegate }
    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || delegate?.responds(to: aSelector) == true
    }
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        delegate?.responds(to: aSelector) == true ? delegate : nil
    }
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        tasks += 1
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, didCreateTask: task)
    }
}
