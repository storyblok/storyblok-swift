import Foundation
import Combine
import Logging
import URLSessionExtension

private let log = Logger(label: "com.storyblok.ContentDeliveryClient")

/// A client for the Storyblok [Content Delivery API](https://www.storyblok.com/docs/api/content-delivery/v2).
///
/// Provides type-safe access to stories with automatic JSON decoding and [relation
/// resolution](https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-with-resolved-relations).
///
/// Create a client by providing your API access token and a content version:
/// ```swift
/// let client = StoryblokClient(accessToken: "YOUR_ACCESS_TOKEN", version: .draft)
/// ```
///
/// Fetch stories by slug or UUID:
/// ```swift
/// let cancellable = client.story("articles/hello-world", as: Article.self)
///     .sink(
///         receiveCompletion: { _ in },
///         receiveValue: { story in print(story.name) }
///     )
/// ```
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
public final class StoryblokClient<Library: BlockLibrary>: Sendable {

    /// An error thrown by ``StoryblokClient`` when a request fails.
    public struct Error: Swift.Error, LocalizedError, Sendable {

        /// A message describing the error, typically the body of the API response.
        public let message: String?

        /// The underlying error, if any.
        public let underlyingError: (any Swift.Error)?

        public init(message: String? = nil, underlyingError: (any Swift.Error)? = nil) {
            self.message = message
            self.underlyingError = underlyingError
        }

        public var errorDescription: String? {
            message ?? underlyingError?.localizedDescription
        }
    }

    /// The underlying URL session configured for the Storyblok Content Delivery API.
    public let session: URLSession

    internal let relations: String

    /// Custom values merged into every decoder's `userInfo`, for use by
    /// `Decodable` implementations. The relation store key is added on top
    /// during relation-aware decoding.
    public let userInfo: [CodingUserInfoKey: any Sendable]


    /// Creates a client with minimal configuration.
    ///
    /// - Parameters:
    ///   - accessToken: The API access token for authentication.
    ///   - version: The [content version](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension/api/version) to retrieve. Defaults to `.published`.
    ///   - region: Optional [region](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension/api/region) depending on the server location of your space. Defaults to `.eu`.
    ///   - language: Optional language code for localized content.
    ///   - fallbackLanguage: Optional fallback language for untranslated fields.
    ///   - cv: Optional cache version timestamp.
    ///   - requestsPerSecond: Optional maximum number of API requests per second. Defaults to `1000`.
    ///   - userInfo: Custom values merged into every decoder's `userInfo`, for use by `Decodable` implementations. Defaults to empty.
    ///   - configuration: The [`URLSessionConfiguration`](https://developer.apple.com/documentation/foundation/urlsessionconfiguration) to use for the underlying session. Defaults to `.default`.
    public convenience init(
        library: Library.Type,
        accessToken: String,
        version: Api.Version = .published,
        region: Api.Region = .eu,
        language: String? = nil,
        fallbackLanguage: String? = nil,
        cv: String? = nil,
        requestsPerSecond: Int = 1000,
        userInfo: [CodingUserInfoKey: any Sendable] = [:],
        configuration: URLSessionConfiguration = .default,
    ) {
        let session = URLSession(
            storyblok: .cdn(
                accessToken: accessToken,
                language: language,
                fallbackLanguage: fallbackLanguage,
                version: version,
                cv: cv,
                region: region,
                requestsPerSecond: requestsPerSecond
            ),
            configuration: configuration
        )
        self.init(library: library, session: session, userInfo: userInfo)
    }

    /// Creates a client wrapping a pre-configured [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession).
    ///
    /// The session must be configured for the Content Delivery API, see
    /// [`URLSession.init(storyblok:configuration:)`](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension/foundation/urlsession/init(storyblok:configuration:)).
    ///
    /// - Parameters:
    ///   - session: The [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) to use for API requests. It must have been created
    ///     with the [`URLSession.init(storyblok:configuration:)`](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension/foundation/urlsession/init(storyblok:configuration:))
    ///     initializer with [`Api.cdn(...)`](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension/api/cdn(accesstoken:language:fallbacklanguage:version:cv:region:requestspersecond:)).
    ///   - userInfo: Custom values merged into every decoder's `userInfo`, for use by `Decodable` implementations. Defaults to empty.
    public init(
        library: Library.Type,
        session: URLSession,
        userInfo: [CodingUserInfoKey: any Sendable] = [:]
    ) {
        self.relations = library.relations
        self.session = session
        self.userInfo = userInfo
    }

    /// Releases the resources held by the underlying [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession).
    ///
    /// After calling this method the client and its session must no longer be used.
    public func close() {
        session.finishTasksAndInvalidate()
    }

    /// Retrieves a story by its slug.
    ///
    /// - Parameters:
    ///   - slug: The URL path segment identifying the story.
    /// - Returns: A publisher emitting the story. The publisher may emit a cached value first
    ///   when one is available locally, followed by a fresh value from the network, and ignores
    ///   the fresh value when it matches the cached value.
    public func story<Content>(_ slug: String, resolveLevel: Int = 1) -> AnyPublisher<Story<Content>, Error> {
        storyPublisher(path: "stories/\(slug)", resolveLevel: resolveLevel)
    }

    /// Retrieves a story by its UUID.
    ///
    /// - Parameters:
    ///   - uuid: The unique identifier of the story.
    /// - Returns: A publisher emitting the story. The publisher may emit a cached value first
    ///   when one is available locally, followed by a fresh value from the network, and ignores
    ///   the fresh value when it matches the cached value.
    public func story<Content>(_ uuid: UUID, resolveLevel: Int = 1) -> AnyPublisher<Story<Content>, Error> {
        storyPublisher(path: "stories/\(uuid.uuidString.lowercased())", findByUuid: true, resolveLevel: resolveLevel)
    }

    // MARK: -

    private func storyPublisher<Content : Decodable>(path: String, findByUuid: Bool = false, resolveLevel: Int = 1) -> AnyPublisher<Story<Content>, Error> {
        let request = buildRequest(path: path, findByUuid: findByUuid, resolveLevel: resolveLevel)

        var cachedRequest = request
        cachedRequest.cachePolicy = .returnCacheDataDontLoad

        let cached = session.dataTaskPublisher(for: cachedRequest)
            .map { $0.data }
            .catch { _ in Empty<Data, URLError>() }
            .mapError { $0 as any Swift.Error }

        let fresh = session.dataTaskPublisher(for: request)
            .failOnErrorResponse(.recoverable)
            .retry(3)
            .failOnErrorResponse(.all)
            .tryMap { (data, _) in data }

        return cached
            .append(fresh)
            .removeDuplicates()
            .tryMap { data in
                let decoder: JSONDecoder
                if resolveLevel > 0 {
                    let store = RelationStore()
                    store.resolveLevel = resolveLevel
                    decoder = Self.makeDecoder(userInfo: self.userInfo, relStore: store)
                } else {
                    decoder = Self.makeDecoder(userInfo: self.userInfo)
                }
                return try decoder.decode(StoryResponse<Content>.self, from: data).story
            }
            .mapError { error in
                if let error = error as? Error { return error }
                if let error = error as? Api.ResponseError {
                    switch error {
                        case let .client(_, data, _), let .server(_, data, _):
                            let message = String(data: data, encoding: .utf8)
                            return Error(message: message, underlyingError: error)
                    }
                }
                return Error(message: error.localizedDescription, underlyingError: error)
            }
            .eraseToAnyPublisher()
    }

    private func buildRequest(path: String, findByUuid: Bool, resolveLevel: Int) -> URLRequest {
        var request = URLRequest(storyblok: session, path: path)
        var queryItems: [URLQueryItem] = []
        if resolveLevel > 0 && !relations.isEmpty {
            queryItems.append(URLQueryItem(name: "resolve_relations", value: relations))
        }
        if resolveLevel >= 2 {
            queryItems.append(URLQueryItem(name: "resolve_level", value: String(resolveLevel)))
        }
        if findByUuid {
            queryItems.append(URLQueryItem(name: "find_by", value: "uuid"))
        }
        if !queryItems.isEmpty {
            request.url!.append(queryItems: queryItems)
        }
        return request
    }

    /// Returns a `JSONDecoder` configured with Storyblok's date formats, custom `userInfo`, and an optional relation store.
    internal static func makeDecoder(
        userInfo: [CodingUserInfoKey: any Sendable] = [:],
        relStore: RelationStore? = nil
    ) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            if let date = isoFormatterFractional.date(from: string) { return date }
            if let date = isoFormatter.date(from: string) { return date }
            if let date = localDateFormatter.date(from: string) { return date }
            if let date = localDateTimeFormatter.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(
                in: try decoder.singleValueContainer(),
                debugDescription: "Cannot decode date from string: \(string)"
            )
        }
        decoder.userInfo = userInfo
        if let relStore {
            decoder.userInfo[.storyblokRelations] = relStore
        }
        return decoder
    }
}

// MARK: - Date formatters

nonisolated(unsafe) private let isoFormatterFractional: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

nonisolated(unsafe) private let isoFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()

private let localDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}()

private let localDateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    formatter.timeZone = TimeZone(identifier: "UTC")
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}()
