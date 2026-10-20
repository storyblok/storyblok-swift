import Testing
import Foundation
import URLSessionExtension
@testable import StoryblokClient

/// The request any paged endpoint makes, exercised through an endpoint other than stories.
///
/// Served by a stub protocol only this suite's session uses, rather than Mocker, whose shared
/// registrations other suites clear while they run alongside this one.
@Suite(.serialized)
struct URLSessionPagesTests {

    struct Entry : Decodable {
        let id: Int
        let name: String
    }

    struct Entries : Decodable {
        let datasource_entries: [Entry]
    }

    /// Answers every request with one canned response, recording the query of each. The response
    /// is not stored, so the cache stays cold: URLSession fails each cache-only request itself,
    /// without asking the stub.
    final class Stub : URLProtocol {

        nonisolated(unsafe) static var headers: [String: String] = [:]
        nonisolated(unsafe) static var body = Data()
        nonisolated(unsafe) static var queries: [[String: String]] = []
        static let lock = NSLock()

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
        override func stopLoading() {}

        override func startLoading() {
            let (headers, body) = Self.lock.withLock {
                let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
                Self.queries.append(Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { _, last in last }))
                return (Self.headers, Self.body)
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: headers.merging(["Content-Type": "application/json"]) { stated, _ in stated }
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [Stub.self]
        session = URLSession(storyblok: .cdn(accessToken: "mock-api-key", version: .draft, cv: "mock-cv"), configuration: configuration)
    }

    /// Serves `body` with `headers` and returns the first value the publisher for page `number`
    /// emits, with the query of each request made for it.
    private func fetchPage(
        _ number: Int = 1,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: String = #"{ "datasource_entries": [{ "id": 1, "name": "a" }, { "id": 2, "name": "b" }] }"#
    ) async throws -> (page: Page<Entry>?, queries: [[String: String]]) {
        Stub.lock.withLock {
            Stub.headers = headers
            Stub.body = Data(body.utf8)
            Stub.queries = []
        }

        let page = try await session
            .page(number, of: "datasource_entries", size: 2, queryItems: queryItems) { body in
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
        let (page, queries) = try await fetchPage(3, headers: ["Total": "6"])

        #expect(try #require(queries.last)["page"] == "3")
        let third = try #require(page)
        #expect(third.number == 3)
        #expect(third.hasNextPage == false, "pages 1 to 3 hold all six")
    }

    @Test
    func `decodes the elements and reads the Total header`() async throws {
        let (page, _) = try await fetchPage(headers: ["Total": "3"])

        let first = try #require(page)
        #expect(first.map(\.name) == ["a", "b"])
        #expect(first.total == 3)
        #expect(first.hasNextPage)
    }

    @Test
    func `without a Total header, a full page is not taken as the last`() async throws {
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
