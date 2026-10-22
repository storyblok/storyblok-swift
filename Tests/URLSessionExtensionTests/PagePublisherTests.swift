import Testing
import Foundation
import URLSessionExtension

/// The request a paged endpoint's publisher makes, and the page it reads from the response.
///
/// Served by a stub protocol only this suite's session uses, rather than Mocker, whose shared
/// registrations other suites clear while they run alongside this one.
@Suite(.serialized)
struct PagePublisherTests {

    struct Entry : Decodable {
        let id: Int
        let name: String
    }

    struct Entries : Decodable {
        let datasource_entries: [Entry]
    }

    /// Answers a cache-only request with the cached response URLSession hands it, and every other
    /// request with one canned response, recording the query of each. The canned response is not
    /// stored, so the cache holds only what a test puts there; when it holds nothing, URLSession
    /// fails a cache-only request itself, without asking the stub.
    final class Stub : URLProtocol {

        nonisolated(unsafe) static var status = 200
        nonisolated(unsafe) static var headers: [String: String] = [:]
        nonisolated(unsafe) static var body = Data()
        nonisolated(unsafe) static var queries: [[String: String]] = []
        static let lock = NSLock()

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func stopLoading() {}

        override func startLoading() {
            if request.cachePolicy == .returnCacheDataDontLoad, let cachedResponse {
                client?.urlProtocol(self, cachedResponseIsValid: cachedResponse)
                return
            }
            let (status, headers, body) = Self.lock.withLock {
                let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
                Self.queries.append(Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { _, last in last }))
                return (Self.status, Self.headers, Self.body)
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: headers.merging(["Content-Type": "application/json"]) { stated, _ in stated }
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    let cache = URLCache(memoryCapacity: 1_000_000, diskCapacity: 0)
    let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Stub.self]
        configuration.urlCache = cache
        session = URLSession(storyblok: .cdn(accessToken: "mock-api-key", version: .draft, cv: "mock-cv"), configuration: configuration)
    }

    @Test
    func `keeps the request as given, adding the page only when it is sent`() throws {
        let request = URLRequest(storyblok: session, path: "datasource_entries")
        let publisher = session.pagePublisher(for: request, page: 3, perPage: 50) { _ in [Entry]() }

        #expect(publisher.request == request)
        #expect(publisher.page == 3)
        #expect(publisher.perPage == 50)
        #expect(publisher.session === session)
        let query = try #require(URLComponents(url: publisher.request.url!, resolvingAgainstBaseURL: false))
        #expect(query.queryItems?.contains { $0.name == "page" } != true)
    }

    @Test
    func `pages a Management API endpoint the same way`() async throws {
        serve(headers: ["total": "3"])
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Stub.self]
        let mapi = URLSession(storyblok: .mapi(accessToken: .personal("mock-token")), configuration: configuration)

        let request = URLRequest(storyblok: mapi, path: "spaces/1/datasource_entries")
        let page = try await mapi
            .pagePublisher(for: request, page: 2, perPage: 2) { body in
                try JSONDecoder().decode(Entries.self, from: body).datasource_entries
            }
            .values
            .first { _ in true }

        let query = try #require(Stub.lock.withLock { Stub.queries.last })
        #expect(query["page"] == "2")
        #expect(query["per_page"] == "2")
        #expect(page?.number == 2)
        #expect(page?.hasNextPage == false, "pages 1 and 2 hold all three")
    }

    private static let entries = #"{ "datasource_entries": [{ "id": 1, "name": "a" }, { "id": 2, "name": "b" }] }"#

    /// Has the stub answer every request that reaches it with `status`, `headers` and `body`.
    private func serve(status: Int = 200, headers: [String: String] = [:], body: String = Self.entries) {
        Stub.lock.withLock {
            Stub.status = status
            Stub.headers = headers
            Stub.body = Data(body.utf8)
            Stub.queries = []
        }
        cache.removeAllCachedResponses()
    }

    /// Puts a response holding `names` in the cache for page 1 of `request`, as a previous fetch
    /// of it would have.
    private func cache(_ names: [String], forPage1Of request: URLRequest) {
        var paged = request
        paged.url!.append(queryItems: [URLQueryItem(name: "page", value: "1"), URLQueryItem(name: "per_page", value: "2")])
        paged.url = paged.url!.sortingQueryItems()
        let entries = names.enumerated().map { #"{ "id": \#($0.offset + 1), "name": "\#($0.element)" }"# }
        let body = #"{ "datasource_entries": ["# + entries.joined(separator: ",") + "] }"
        let response = HTTPURLResponse(url: paged.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
        cache.storeCachedResponse(CachedURLResponse(response: response, data: Data(body.utf8)), for: paged)
    }

    /// Every page `publisher` delivers, by the names of its entries.
    private func names<Upstream>(_ publisher: URLSession.PagePublisher<Upstream, Entry>) async throws -> [[String]] {
        var pages: [[String]] = []
        for try await page in publisher.values { pages.append(page.map(\.name)) }
        return pages
    }

    @Test
    func `by default the page is fetched fresh, without the cached copy`() async throws {
        serve()
        let request = URLRequest(storyblok: session, path: "datasource_entries")
        cache(["cached"], forPage1Of: request)

        let pages = try await names(session.pagePublisher(for: request, page: 1, perPage: 2) { body in
            try JSONDecoder().decode(Entries.self, from: body).datasource_entries
        })

        #expect(pages == [["a", "b"]])
    }

    @Test
    func `with CachedDataTaskPublisher upstream the cached copy comes first`() async throws {
        serve()
        let request = URLRequest(storyblok: session, path: "datasource_entries")
        cache(["cached"], forPage1Of: request)

        let pages = try await names(session.pagePublisher(
            for: request, page: 1, perPage: 2, upstream: URLSession.CachedDataTaskPublisher.init
        ) { body in
            try JSONDecoder().decode(Entries.self, from: body).datasource_entries
        })

        #expect(pages == [["cached"], ["a", "b"]])
    }

    @Test
    func `an error response fails with a ResponseError, not a decoding error`() async throws {
        serve(status: 404, body: #"{ "error": "not found" }"#)
        let request = URLRequest(storyblok: session, path: "datasource_entries")

        await #expect(throws: Api.ResponseError.self) {
            _ = try await names(session.pagePublisher(for: request, page: 1, perPage: 2) { body in
                try JSONDecoder().decode(Entries.self, from: body).datasource_entries
            })
        }
    }

    /// Serves `body` with `headers` and returns the first value the publisher for page `number`
    /// emits, with the query of each request made for it.
    private func fetchPage(
        _ number: Int = 1,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: String = Self.entries
    ) async throws -> (page: Page<Entry>?, queries: [[String: String]]) {
        serve(headers: headers, body: body)

        var request = URLRequest(storyblok: session, path: "datasource_entries")
        request.url!.append(queryItems: queryItems)
        let page = try await session
            .pagePublisher(for: request, page: number, perPage: 2) { body in
                try JSONDecoder().decode(Entries.self, from: body).datasource_entries
            }
            .values
            .first { _ in true }
        return (page, Stub.lock.withLock { Stub.queries })
    }

    @Test
    func `asks for page 1 at the page size, alongside the endpoint's own parameters`() async throws {
        let (_, queries) = try await fetchPage(queryItems: [URLQueryItem(name: "datasource", value: "colors")])

        let query = try #require(queries.last)
        #expect(query["page"] == "1")
        #expect(query["per_page"] == "2")
        #expect(query["datasource"] == "colors")
    }

    @Test
    func `asks for the page given, and counts the total from it`() async throws {
        let (page, queries) = try await fetchPage(3, headers: ["total": "6"])  // as the API docs spell it

        #expect(try #require(queries.last)["page"] == "3")
        let third = try #require(page)
        #expect(third.number == 3)
        #expect(third.hasNextPage == false, "pages 1 to 3 hold all six")
    }

    @Test
    func `decodes the elements and reads the total header`() async throws {
        let (page, _) = try await fetchPage(headers: ["Total": "3"])

        let first = try #require(page)
        #expect(first.map(\.name) == ["a", "b"])
        #expect(first.total == 3)
        #expect(first.hasNextPage)
    }

    @Test
    func `without a total header, a full page is not taken as the last`() async throws {
        let (page, _) = try await fetchPage()

        let first = try #require(page)
        #expect(first.total == nil)
        #expect(first.hasNextPage)
    }

    @Test
    func `a body that is not the endpoint's shape fails with a DecodingError`() async throws {
        await #expect {
            _ = try await self.fetchPage(body: #"{ "stories": [] }"#)
        } throws: { error in
            error is DecodingError
        }
    }
}
