import Foundation
import Combine
import Logging

private let log = Logger(label: "com.storyblok.URLSessionExtension")

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public extension URLSession {

    convenience init(storyblok api: Api) {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        self.init(configuration: configuration, delegate: Storyblok(api: api, delegate: nil), delegateQueue: nil)
    }

    convenience init(storyblok api: Api, configuration: URLSessionConfiguration) {
        self.init(configuration: configuration, delegate: Storyblok(api: api, delegate: nil), delegateQueue: nil)
    }

    convenience init(storyblok api: Api, configuration: URLSessionConfiguration, delegate: (any URLSessionDelegate)?, delegateQueue queue: OperationQueue?) {
        self.init(configuration: configuration, delegate: Storyblok(api: api, delegate: delegate), delegateQueue: queue)
    }
}

public enum Api : Sendable {

    case cdn(
        accessToken: String,
        language: String? = nil,
        fallbackLanguage: String? = nil,
        version: Version = .published,
        cv: String? = nil,
        region: Region = .eu,
        requestsPerSecond: Int = 1000
    )

    case mapi(
        accessToken: AccessToken,
        region: Region = .eu,
        requestsPerSecond: Int = 6
    )

    public enum Region : Sendable {
        case eu
        case usa
        case can
        case aus
        case chn
        case custom(url: URL)
    }


    public enum Version: String, Sendable {
        case draft = "draft"
        case published = "published"
    }

    public enum AccessToken : Sendable {
        case oauth(token: String)
        case personal(token: String)
    }


    enum ResponseError: Error {
        case client(statusCode: Int, data: Data, response: URLResponse)
        case server(statusCode: Int, data: Data, response: URLResponse)
    }
}

public extension URLSession.DataTaskPublisher {

    enum ErrorResponseType {
        case recoverable
        case all
    }

    func failOnErrorResponse(_ type: ErrorResponseType) -> AnyPublisher<(data: Data, response: URLResponse), Error> {
        tryFilter { (data, response) in
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            switch statusCode {
                case 429: throw Api.ResponseError.client(statusCode: statusCode, data: data, response: response)
                case 400..<500 where type == .all: throw Api.ResponseError.client(statusCode: statusCode, data: data, response: response)
                case 500..<600: throw Api.ResponseError.server(statusCode: statusCode, data: data, response: response)
                default: return true
            }
        }
        .eraseToAnyPublisher()
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public extension URLRequest {
    init(storyblok session: URLSession, path: String, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 60.0) {
        let api: Api = (session.delegate as! Storyblok).api
        switch api {
            case let .cdn(accessToken, language, fallbackLanguage, version, cv, region, _):
                var cachePolicy = cachePolicy
                var url = switch region {
                    case .eu: URL(string: "https://api.storyblok.com/v2/cdn/")!
                    case .usa: URL(string: "https://api-us.storyblok.com/v2/cdn/")!
                    case .can: URL(string: "https://api-ca.storyblok.com/v2/cdn/")!
                    case .aus: URL(string: "https://api-ap.storyblok.com/v2/cdn/")!
                    case .chn: URL(string: "https://app.storyblokchina.cn/v2/cdn/")!
                    case .custom(url: let url): url
                }
                url.append(path: path)
                url.append(queryItems: [URLQueryItem(name: "token", value: accessToken), URLQueryItem(name: "version", value: version.rawValue)])
                if let cv = cv {
                    url.append(queryItems: [URLQueryItem(name: "cv", value: cv)])
                    //override default cache policy to serve subsequent requests for the same resource from the cache
                    if(cachePolicy == .useProtocolCachePolicy) {
                        cachePolicy = .returnCacheDataElseLoad
                    }
                }
                if let language = language {
                    url.append(queryItems: [URLQueryItem(name: "language", value: language)])
                }
                if let fallbackLanguage = fallbackLanguage {
                    url.append(queryItems: [URLQueryItem(name: "fallback_lang", value: fallbackLanguage)])
                }
                self.init(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
            case let .mapi(accessToken, region, _):
                var url = switch region {
                    case .eu: URL(string: "https://mapi.storyblok.com/v1/")!
                    case .usa: URL(string: "https://api-us.storyblok.com/v1/")!
                    case .can: URL(string: "https://api-ca.storyblok.com/v1/")!
                    case .aus: URL(string: "https://api-ap.storyblok.com/v1/")!
                    case .chn: URL(string: "https://app.storyblokchina.cn/v1/")!
                    case .custom(url: let url): url
                }
                url.append(path: path)
                self.init(url: url, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
                setValue("application/json", forHTTPHeaderField: "Content-Type")
                switch accessToken {
                    case .oauth(token: let token):
                        let value = if token.hasPrefix("Bearer") { token } else { "Bearer \(token)" }
                        setValue(value, forHTTPHeaderField: "Authorization")
                    case .personal(token: let token):
                        setValue(token, forHTTPHeaderField: "Authorization")
                }
            }
    }
}

@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
internal final class Storyblok: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    var api: Api
    private let delegate: (any URLSessionDelegate)?
    private let minDelayBetweenRequests: Duration
    private var failedRequestCount = 0
    private var backoffUntil = DispatchTime.now() // to share back off across all requests pre-flight
    private var observers: [URLSessionTask : NSKeyValueObservation] = [:]

    init(api: Api, delegate: (any URLSessionDelegate)?) {
        self.api = api
        self.delegate = delegate
        let requestsPerSecond = switch api {
            case let .cdn(_, _, _, _, _, _, it): it
            case let .mapi(_, _, it): it
        }
        self.minDelayBetweenRequests = .seconds(1) / requestsPerSecond
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        nonisolated(unsafe) var previousState = task.state
        observers[task] = task.observe(\.state) { [self] task, _ in
            switch task.state {
                case .running:
                    suspendIfNecessary: switch(previousState) {
                        case .running: break
                        case .suspended where backoffUntil > .now():
                            switch(task.currentRequest!.cachePolicy) {
                                case .returnCacheDataDontLoad: break suspendIfNecessary
                                case .returnCacheDataElseLoad where session.configuration.urlCache?.cachedResponse(for: task.currentRequest!) != nil: break suspendIfNecessary
                                default: break
                            }
                            log.debug("Suspending task", metadata: [
                              "task.currentRequest.url": "\(task.currentRequest?.url?.absoluteString ?? "?")",
                              "delay": "\(DispatchTime.now().distance(to: backoffUntil))"
                            ])
                            task.suspend()
                            DispatchQueue.main.asyncAfter(deadline: backoffUntil) { task.resume() }
                        default:
                            backoffUntil = max(backoffUntil, .now() + minDelayBetweenRequests / .seconds(1))
                    }
                case .canceling:
                    observers.removeValue(forKey: task)
                case .completed:
                    observers.removeValue(forKey: task)
                    switch (task.response as? HTTPURLResponse)?.statusCode ?? 0 {
                        case 0, 429, 500..<600:
                            failedRequestCount += 1
                            backoffUntil = max(backoffUntil, .now() + min(pow(2.0, Double(failedRequestCount)), 60) + Double.random(in: 0..<1.0))
                        default:
                            failedRequestCount = 0
                    }
                default:
                    break
            }
            previousState = task.state
        }
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, didCreateTask: task)
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
        delegate?.urlSession?(session, didBecomeInvalidWithError: error)
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @Sendable @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        delegate?.urlSession?(session, didReceive: challenge, completionHandler: completionHandler) ?? completionHandler(.performDefaultHandling, nil)
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        delegate?.urlSessionDidFinishEvents?(forBackgroundURLSession: session)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @Sendable @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didReceive: challenge, completionHandler: completionHandler) ?? completionHandler(.performDefaultHandling, nil)
    }


    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didFinishCollecting: metrics)

    }

    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, taskIsWaitingForConnectivity: task)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @Sendable @escaping (InputStream?) -> Void) {
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, needNewBodyStream: completionHandler) ?? completionHandler(nil)
    }

    @available(macOS 14.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStreamFrom offset: Int64, completionHandler: @Sendable @escaping (InputStream?) -> Void) {
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, needNewBodyStreamFrom: offset, completionHandler: completionHandler) ?? completionHandler(nil)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didCompleteWithError: error)

    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest, completionHandler: @Sendable @escaping (URLSession.DelayedRequestDisposition, URLRequest?) -> Void) {
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, willBeginDelayedRequest: request, completionHandler: completionHandler) ?? completionHandler(.continueLoading, nil)
    }

    @available(macOS 14.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceiveInformationalResponse response: HTTPURLResponse) {
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didReceiveInformationalResponse: response)

    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @Sendable @escaping (URLRequest?) -> Void) {
        var request = request
        if case let .cdn(accessToken, language, fallbackLanguage, version, _, region, requestsPerSecond) = api {
            let components = URLComponents(string: request.url?.absoluteString ?? "")!
            if let cv = components.queryItems?.first(where: { $0.name == "cv" })?.value {
                log.info("Updating cv", metadata: ["cv": "\(cv)"])
                api = .cdn(accessToken: accessToken, language: language, fallbackLanguage: fallbackLanguage, version: version, cv: cv, region: region, requestsPerSecond: requestsPerSecond)
                //override default cache policy to serve the new request from the cache if present now we have a cv
                if(request.cachePolicy == .useProtocolCachePolicy) {
                    request.cachePolicy = .returnCacheDataElseLoad
                }
            }
        }
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler) ?? completionHandler(request)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, didSendBodyData: bytesSent, totalBytesSent: totalBytesSent, totalBytesExpectedToSend: totalBytesExpectedToSend)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        (delegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        (delegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        (delegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didReceive: data)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @Sendable @escaping (URLSession.ResponseDisposition) -> Void) {
        (delegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler) ?? completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @Sendable @escaping (CachedURLResponse?) -> Void) {
        (delegate as? URLSessionDataDelegate)?.urlSession?(session, dataTask: dataTask, willCacheResponse: proposedResponse, completionHandler: completionHandler) ?? completionHandler(proposedResponse)
    }

}


