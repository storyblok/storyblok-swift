import Foundation
import Combine
import Logging
import URLSessionExtension

private let log = Logger(label: "com.storyblok.StoryblokClient")

/// A client for the Storyblok [Content Delivery API](https://www.storyblok.com/docs/api/content-delivery/v2).
///
/// Provides type-safe access to stories with automatic JSON decoding and [relation
/// resolution](https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-with-resolved-relations).
///
/// The client is generic over a ``BlockLibrary`` — a type (typically an `enum` annotated with
/// the ``BlockLibrary()`` macro) that enumerates the Storyblok components your space uses. The
/// library drives both content decoding and which relations are resolved.
///
/// Create a client by providing your block library, API access token, and a content version:
/// ```swift
/// let client = StoryblokClient(library: Content.self, accessToken: "YOUR_ACCESS_TOKEN", version: .draft)
/// ```
///
/// Fetch stories by slug or UUID. The decoded content type is inferred from the value you bind,
/// and may be the library itself or any `Decodable` type matching the story's content:
/// ```swift
/// // Combine
/// let cancellable = client.story("articles/hello-world")
///     .sink(
///         receiveCompletion: { _ in },
///         receiveValue: { (story: Story<Content>) in print(story.name) }
///     )
///
/// // async/await, via the publisher's `values` sequence
/// let story: Story<Content>? = try await client.story("articles/hello-world")
///     .values
///     .first { _ in true }
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

    /// Creates a client with minimal configuration.
    ///
    /// - Parameters:
    ///   - library: The ``BlockLibrary`` type describing the components this client decodes and
    ///     the relations it resolves.
    ///   - accessToken: The API access token for authentication.
    ///   - version: The [content version](doc:/URLSessionExtension/Api/Version) to retrieve. Defaults to `.published`.
    ///   - region: Optional [region](doc:/URLSessionExtension/Api/Region) depending on the server location of your space. Defaults to `.eu`.
    ///   - language: Optional language code for localized content.
    ///   - fallbackLanguage: Optional fallback language for untranslated fields.
    ///   - cv: Optional cache version timestamp.
    ///   - requestsPerSecond: Optional maximum number of API requests per second. Defaults to `1000`.
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
        self.init(library: library, session: session)
    }

    /// Creates a client wrapping a pre-configured [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession).
    ///
    /// The session must be configured for the Content Delivery API, see
    /// [`URLSession.init(storyblok:configuration:)`](doc:/URLSessionExtension/Foundation/URLSession/init(storyblok:configuration:)).
    ///
    /// - Parameters:
    ///   - library: The ``BlockLibrary`` type describing the components this client decodes and
    ///     the relations it resolves.
    ///   - session: The [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) to use for API requests. It must have been created
    ///     with the [`URLSession.init(storyblok:configuration:)`](doc:/URLSessionExtension/Foundation/URLSession/init(storyblok:configuration:))
    ///     initializer with [`Api.cdn(...)`](doc:/URLSessionExtension/Api/cdn(accessToken:language:fallbackLanguage:version:cv:region:requestsPerSecond:)).
    public init(
        library: Library.Type,
        session: URLSession,
    ) {
        self.relations = library.relations
        self.session = session
    }

    /// Releases the resources held by the underlying [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession).
    ///
    /// After calling this method the client and its session must no longer be used.
    public func close() {
        session.finishTasksAndInvalidate()
    }

    /// Retrieves a story by its slug.
    ///
    /// The decoded `Content` type is inferred from the context in which the result is used. It is
    /// commonly the ``BlockLibrary`` itself, but may be any `Decodable` type that matches the
    /// shape of the story's `content` object (for example a single nested block struct).
    ///
    /// - Parameters:
    ///   - slug: The URL path segment identifying the story.
    ///   - resolveLevel: How deeply nested ``Story`` relations are resolved. `1` (the default)
    ///     resolves direct relations; higher values resolve relations of relations; `0` disables
    ///     relation resolution entirely, leaving relation fields as raw UUID strings. See
    ///     <doc:UserGuide#Story-relations>.
    /// - Returns: A publisher emitting the story. The publisher may emit a cached value first
    ///   when one is available locally, followed by a fresh value from the network, and ignores
    ///   the fresh value when it matches the cached value.
    public func story<Content>(_ slug: String, resolveLevel: Int = 1) -> AnyPublisher<Story<Content>, Error> {
        storyPublisher(path: "stories/\(slug)", resolveLevel: resolveLevel)
    }

    /// Retrieves a story by its UUID.
    ///
    /// The decoded `Content` type is inferred from the context in which the result is used. It is
    /// commonly the ``BlockLibrary`` itself, but may be any `Decodable` type that matches the
    /// shape of the story's `content` object (for example a single nested block struct).
    ///
    /// - Parameters:
    ///   - uuid: The unique identifier of the story.
    ///   - resolveLevel: How deeply nested ``Story`` relations are resolved. `1` (the default)
    ///     resolves direct relations; higher values resolve relations of relations; `0` disables
    ///     relation resolution entirely, leaving relation fields as raw UUID strings. See
    ///     <doc:UserGuide#Story-relations>.
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
                    decoder = Self.makeDecoder(relStore: store)
                } else {
                    decoder = Self.makeDecoder()
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

    /// Returns a `JSONDecoder` configured with Storyblok's date formats and an optional relation store.
    internal static func makeDecoder(relStore: RelationStore? = nil) -> JSONDecoder {
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
