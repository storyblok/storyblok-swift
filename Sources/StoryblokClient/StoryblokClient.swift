import Foundation
import Combine
import Logging
import URLSessionExtension

private let log = Logger(label: "com.storyblok.StoryblokClient")

/// A client for the Storyblok [Content Delivery API](https://www.storyblok.com/docs/api/content-delivery/v2).
///
/// Provides type-safe access to stories with automatic JSON decoding and relation resolution.
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
    ///
    /// The cases separate failures that a retry may resolve from those it cannot: ``api(message:underlyingError:)``
    /// reports a failed request, while ``decoding(_:)`` reports content that does not match your ``BlockLibrary``.
    public enum Error: Swift.Error, LocalizedError, Sendable {

        /// The request failed. Retrying may succeed.
        ///
        /// - Parameters:
        ///   - message: A message describing the error, typically the body of the API response.
        ///   - underlyingError: The underlying error, if any.
        case api(message: String?, underlyingError: (any Swift.Error)?)

        /// The response could not be decoded because the content does not match the types it was decoded into.
        /// Retrying cannot resolve this — correct your ``BlockLibrary`` or the story's model instead.
        case decoding(DecodingError)

        /// A message describing the error, typically the body of the API response.
        public var message: String? {
            switch self {
                case let .api(message, _): message
                case let .decoding(error): error.localizedDescription
            }
        }

        /// The underlying error, if any.
        public var underlyingError: (any Swift.Error)? {
            switch self {
                case let .api(_, underlyingError): underlyingError
                case let .decoding(error): error
            }
        }

        public var errorDescription: String? {
            message ?? underlyingError?.localizedDescription
        }

        /// Maps a failure from the request or the decode onto this client's own error.
        ///
        /// A decoding failure stays a decoding failure: content that does not match your types is a
        /// modelling error rather than a transient one, and retrying cannot resolve it.
        static func from(_ error: any Swift.Error) -> Self {
            if let error = error as? DecodingError { return .decoding(error) }
            if let error = error as? Self { return error }
            if let error = error as? Api.ResponseError {
                switch error {
                    case let .client(_, data, _), let .server(_, data, _):
                        return .api(message: String(data: data, encoding: .utf8), underlyingError: error)
                }
            }
            return .api(message: error.localizedDescription, underlyingError: error)
        }
    }

    /// The underlying URL session configured for the Storyblok Content Delivery API.
    public let session: URLSession

    internal let relations: String

    /// Creates a client.
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
    ///   - delegate: An optional delegate for the underlying session.
    ///   - delegateQueue: An optional queue for scheduling `delegate` callbacks.
    public init(
        library: Library.Type,
        accessToken: String,
        version: Api.Version = .published,
        region: Api.Region = .eu,
        language: String? = nil,
        fallbackLanguage: String? = nil,
        cv: String? = nil,
        requestsPerSecond: Int = 1000,
        configuration: URLSessionConfiguration = .default,
        delegate: (any URLSessionDelegate)? = nil,
        delegateQueue: OperationQueue? = nil,
    ) {
        self.relations = library.relations
        self.session = URLSession(
            storyblok: .cdn(
                accessToken: accessToken,
                language: language,
                fallbackLanguage: fallbackLanguage,
                version: version,
                cv: cv,
                region: region,
                requestsPerSecond: requestsPerSecond
            ),
            configuration: configuration,
            delegate: RedirectNormalizer(delegate: delegate),
            delegateQueue: delegateQueue
        )
    }

    @available(*, unavailable, message: "Pass the configuration, delegate and delegateQueue you gave the session to init(library:accessToken:...) and let the client build the session. Only a session it builds normalizes redirects, so a story is fetched once per cache version rather than twice.")
    public init(
        library: Library.Type,
        session: URLSession,
    ) {
        fatalError("unavailable")
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
    ///     relation resolution entirely. With resolution disabled, optional ``Story`` fields
    ///     decode as `nil` and non-optional ``Story`` fields fail decoding — model relation
    ///     fields as `UUID` (or `String`) to receive the raw UUIDs instead. See
    ///     <doc:UserGuide#Story-relations>.
    ///   - query: Configures the query parameters, such as ``StoryQuery/fromRelease``.
    /// - Returns: A publisher emitting the story. The publisher may emit a cached value first
    ///   when one is available locally, followed by a fresh value from the network, and ignores
    ///   the fresh value when it matches the cached value. Failures are reported as an ``Error``,
    ///   whose case distinguishes a failed request from content that does not match your types.
    public func story<Content>(
        _ slug: String,
        resolveLevel: Int = 1,
        query: (inout StoryQuery) -> Void = { _ in }
    ) -> AnyPublisher<Story<Content>, Error> {
        storyPublisher(path: "stories/\(slug)", resolveLevel: resolveLevel, query: StoryQuery(query))
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
    ///     relation resolution entirely. With resolution disabled, optional ``Story`` fields
    ///     decode as `nil` and non-optional ``Story`` fields fail decoding — model relation
    ///     fields as `UUID` (or `String`) to receive the raw UUIDs instead. See
    ///     <doc:UserGuide#Story-relations>.
    ///   - query: Configures the query parameters, such as ``StoryQuery/fromRelease``.
    /// - Returns: A publisher emitting the story. The publisher may emit a cached value first
    ///   when one is available locally, followed by a fresh value from the network, and ignores
    ///   the fresh value when it matches the cached value. Failures are reported as an ``Error``,
    ///   whose case distinguishes a failed request from content that does not match your types.
    public func story<Content>(
        _ uuid: UUID,
        resolveLevel: Int = 1,
        query: (inout StoryQuery) -> Void = { _ in }
    ) -> AnyPublisher<Story<Content>, Error> {
        storyPublisher(path: "stories/\(uuid.uuidString.lowercased())", findByUuid: true, resolveLevel: resolveLevel, query: StoryQuery(query))
    }

    private func storyPublisher<Content : Decodable>(
        path: String,
        findByUuid: Bool = false,
        resolveLevel: Int = 1,
        query: StoryQuery
    ) -> AnyPublisher<Story<Content>, Error> {
        session.cachedDataTaskPublisher(for: buildRequest(path: path, findByUuid: findByUuid, resolveLevel: resolveLevel, queryItems: query.queryItems))
            .tryMap { data, _ in
                try Self.decoder(resolveLevel: resolveLevel).decode(ContentResponse<Story<Content>>.self, from: data).payload
            }
            .mapError { .from($0) }
            .eraseToAnyPublisher()
    }

    /// One page of the stories matching `query`.
    ///
    /// As ``story(_:resolveLevel:query:)-(String,_,_)`` does, the publisher sends the copy of the page the
    /// URL cache holds, if any, then the fresh one, and finishes. The ``/URLSessionExtension/Page`` says whether there
    /// is a page after it; fetch that with `page + 1`, and join it onto the ones before with
    /// ``/URLSessionExtension/Page/+(_:_:)``, which leaves out stories already on an earlier page:
    ///
    /// ```swift
    /// var posts: Page<Story<Block.Post>> = []
    /// var number = 1
    /// repeat {
    ///     let stories: AnyPublisher<Page<Story<Block.Post>>, _> = client.stories(page: number)
    ///     var page: Page<Story<Block.Post>> = []
    ///     for try await copy in stories.values { page = copy }  // the fresh copy arrives last
    ///     posts = posts + page
    ///     number += 1
    /// } while posts.hasNextPage
    /// ```
    ///
    /// `StoryblokUI`'s `Stories` view does this for a SwiftUI list, fetching each page as its
    /// last row appears.
    ///
    /// `Content` fixes which component the query addresses: its
    /// ``QueryableContent/technicalName`` becomes `content_type`, so a query typed to one of your
    /// content structs asks only for that component's stories, and one typed to your whole
    /// ``BlockLibrary`` asks for all of them.
    ///
    /// - Parameters:
    ///   - page: The page to fetch, counting from 1.
    ///   - pageSize: Stories per page, sent as `per_page`. The endpoint caps this at 100 and
    ///     refuses a larger value rather than quietly reducing it.
    ///   - resolveLevel: How deeply nested ``Story`` relations are resolved, as for
    ///     ``story(_:resolveLevel:query:)-(String,_,_)``.
    ///   - query: Configures the query parameters.
    public func stories<Content : QueryableContent>(
        page: Int = 1,
        pageSize: Int = 25,
        resolveLevel: Int = 1,
        query: (inout StoriesQuery<Content>) -> Void = { _ in }
    ) -> AnyPublisher<Page<Story<Content>>, Error> {
        let queryItems = relationParameters(resolveLevel: resolveLevel) + StoriesQuery(query).queryItems

        var request = URLRequest(storyblok: session, path: "stories")
        request.url!.append(queryItems: queryItems)

        return session.pagePublisher(for: request, page: page, perPage: pageSize, upstream: URLSession.CachedDataTaskPublisher.init) { body in
            try Self.decoder(resolveLevel: resolveLevel)
                .decode(ContentResponse<[Story<Content>]>.self, from: body)
                .payload
        }
        .mapError { .from($0) }
        .eraseToAnyPublisher()
    }

    // MARK: -

    internal func buildRequest(path: String, findByUuid: Bool, resolveLevel: Int, queryItems: [URLQueryItem] = []) -> URLRequest {
        var request = URLRequest(storyblok: session, path: path)
        request.url!.append(queryItems: relationParameters(resolveLevel: resolveLevel))
        if findByUuid { request.url!.append(queryItems: [URLQueryItem(name: "find_by", value: "uuid")]) }
        request.url!.append(queryItems: queryItems)
        // One spelling per request, so the cache probe finds what the previous fetch stored.
        request.url = request.url!.sortingQueryItems()
        return request
    }

    /// The relation-resolution parameters a story request sends for `resolveLevel`. They come from
    /// the block library rather than from a query.
    func relationParameters(resolveLevel: Int) -> [URLQueryItem] {
        guard resolveLevel > 0, !relations.isEmpty else { return [] }
        var parameters = [URLQueryItem(name: "resolve_relations", value: relations)]
        if resolveLevel >= 2 { parameters.append(URLQueryItem(name: "resolve_level", value: String(resolveLevel))) }
        return parameters
    }

    /// A decoder for one response, resolving relations `resolveLevel` deep from the response's `rels`.
    static func decoder(resolveLevel: Int) -> JSONDecoder {
        guard resolveLevel > 0 else { return makeDecoder() }
        let store = RelationStore()
        store.resolveLevel = resolveLevel
        return makeDecoder(relStore: store)
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
        decoder.userInfo[.storyblokContent] = true
        if let relStore {
            decoder.userInfo[.storyblokRelations] = relStore
        }
        return decoder
    }
}

/// Spells the request a redirect sends us to the same way ``StoryblokClient`` spells the requests that follow it,
/// so that the response is stored under the key they will look for.
///
/// `URLSessionExtension` hands its redirects to the delegate it was given, having already taken the new `cv` from
/// them, so normalizing here leaves that untouched.
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *)
internal final class RedirectNormalizer: NSObject, URLSessionDataDelegate, @unchecked Sendable {

    private let delegate: (any URLSessionDelegate)?

    init(delegate: (any URLSessionDelegate)? = nil) {
        self.delegate = delegate
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @Sendable @escaping (URLRequest?) -> Void
    ) {
        var request = request
        request.url = request.url?.sortingQueryItems(readingPlusAsSpace: true)
        (delegate as? URLSessionTaskDelegate)?.urlSession?(session, task: task, willPerformHTTPRedirection: response, newRequest: request, completionHandler: completionHandler) ?? completionHandler(request)
    }

    //Forward all other calls to the delegate

    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector) || delegate?.responds(to: aSelector) == true
    }

    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        delegate?.responds(to: aSelector) == true ? delegate : nil
    }
}

// MARK: - Blank UUIDs

extension KeyedDecodingContainer {
    /// Specialised overload for optional UUIDs. A single-option field sourced from stories with no story selected,
    /// which Storyblok sends as `""` rather than `null`, decodes as `nil` instead of throwing. Non-optional fields use
    /// `decode`, which does not go through this overload, so a blank UUID still throws for them. Only decoding by
    /// ``StoryblokClient`` is affected: any other decoder reads `""` as Foundation does, and throws.
    public func decodeIfPresent(_ type: UUID.Type, forKey key: Key) throws -> UUID? {
        guard contains(key), !(try decodeNil(forKey: key)) else { return nil }
        if (try? decode(String.self, forKey: key)) == "",
           try superDecoder(forKey: key).userInfo[.storyblokContent] as? Bool == true {
            return nil
        }
        return try decode(UUID.self, forKey: key)
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
