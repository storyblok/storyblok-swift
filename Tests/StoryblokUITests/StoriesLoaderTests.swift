import Testing
import Foundation
import Combine
@testable import StoryblokClient
@testable import StoryblokUI

@Suite("The loader behind Stories")
@MainActor
struct StoriesLoaderTests {

    struct Library : BlockLibrary {}

    struct Item : QueryableContent, Hashable {
        let title: String
    }

    typealias Loader = StoriesLoader<Library, Item>

    /// Story `number`.
    nonisolated private static func story(_ number: Int) -> Story<Item> {
        Story(
            id: Int64(number),
            uuid: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!,
            name: "Story \(number)",
            content: Item(title: "t\(number)"),
            slug: "s\(number)",
            fullSlug: "a/s\(number)",
            createdAt: .distantPast,
            publishedAt: nil,
            firstPublishedAt: nil,
            updatedAt: nil,
            sortByDate: nil,
            position: 0,
            tagList: [],
            isStartPage: false,
            parentId: nil,
            metadata: nil,
            groupId: UUID(),
            releaseId: nil,
            language: "default",
            path: nil,
            alternates: [],
            defaultFullSlug: nil,
            translatedSlugs: nil
        )
    }

    /// Serves each page from a subject the test sends to, recording which pages were asked for.
    final class Server {
        var requested: [Int] = []
        private var subjects: [Int: PassthroughSubject<Page<Story<Item>>, StoryblokClient<Library>.Error>] = [:]

        /// Page `number`, two stories to a page, as `client.stories(page:)` would publish it.
        func stories(page number: Int) -> Loader.PagePublisher {
            requested.append(number)
            let subject = PassthroughSubject<Page<Story<Item>>, StoryblokClient<Library>.Error>()
            subjects[number] = subject
            return subject.eraseToAnyPublisher()
        }

        func send(_ numbers: [Int], total: Int, as page: Int) {
            subjects[page]!.send(Page(numbers.map(StoriesLoaderTests.story), number: page, size: 2, total: total))
        }

        func fail(_ page: Int) {
            subjects[page]!.send(completion: .failure(.api(message: "offline", underlyingError: nil)))
        }
    }

    final class Client {}
    let client = Client()

    private func key(_ queryItems: [URLQueryItem] = []) -> Loader.Key {
        Loader.Key(client: ObjectIdentifier(client), pageSize: 2, resolveLevel: 1, queryItems: queryItems)
    }

    /// Lets the deferred start and the publisher's deliveries run.
    private func settle() async {
        for _ in 0..<5 { await Task.yield() }
        try? await Task.sleep(nanoseconds: 20_000_000)
    }

    /// A loader showing page 1 of `server`'s stories: 1 and 2 of `total`.
    private func loaded(from server: Server, total: Int) async -> Loader {
        let loader = Loader()
        loader.start(key(), server.stories)
        await settle()
        server.send([1, 2], total: total, as: 1)
        await settle()
        return loader
    }

    @Test
    func `starts once SwiftUI has finished updating, then shows the first page`() async {
        let server = Server()
        let loader = Loader()

        loader.start(key(), server.stories)
        #expect(server.requested.isEmpty, "nothing is requested during the update that called start")

        await settle()
        #expect(server.requested == [1])
        server.send([1, 2], total: 4, as: 1)
        await settle()

        #expect(loader.page?.map(\.name) == ["Story 1", "Story 2"])
        #expect(loader.failure == nil)
    }

    @Test
    func `starting with the same request again does not fetch again`() async {
        let server = Server()
        let loader = Loader()

        loader.start(key(), server.stories)
        await settle()
        loader.start(key(), server.stories)
        await settle()

        #expect(server.requested == [1])
    }

    @Test
    func `a different request starts again from page 1`() async {
        let first = Server()
        let second = Server()
        let loader = await loaded(from: first, total: 4)

        loader.start(key([URLQueryItem(name: "search_term", value: "kotlin")]), second.stories)
        await settle()

        #expect(loader.page == nil, "the old results are not shown for the new query")
        #expect(second.requested == [1])
    }

    @Test
    func `loading the next page appends it`() async {
        let server = Server()
        let loader = await loaded(from: server, total: 3)

        loader.load(page: 2)
        await settle()
        server.send([3], total: 3, as: 2)
        await settle()

        #expect(server.requested == [1, 2])
        #expect(loader.page?.map(\.name) == ["Story 1", "Story 2", "Story 3"])
        #expect(loader.page?.number == 2)
        #expect(loader.page?.hasNextPage == false)
    }

    @Test
    func `a page is fetched once however often it is asked for`() async {
        let server = Server()
        let loader = await loaded(from: server, total: 6)

        loader.load(page: 2)
        loader.load(page: 2)
        loader.load(page: 2)
        await settle()

        #expect(server.requested == [1, 2])
    }

    @Test
    func `a fresh copy of an earlier page arriving after a later one replaces it in place`() async {
        let server = Server()
        let loader = await loaded(from: server, total: 4)  // page 1, cached
        loader.load(page: 2)
        await settle()
        server.send([3, 4], total: 4, as: 2)
        await settle()

        server.send([1, 5], total: 4, as: 1)  // page 1, fresh, after page 2
        await settle()

        #expect(loader.page?.map(\.name) == ["Story 1", "Story 5", "Story 3", "Story 4"])
        #expect(loader.page?.number == 2)
    }

    @Test
    func `a failure is shown, and retrying fetches that page again, keeping what loaded`() async {
        let server = Server()
        let loader = await loaded(from: server, total: 4)
        loader.load(page: 2)
        await settle()

        server.fail(2)
        await settle()
        #expect(loader.failure != nil)
        #expect(loader.page?.count == 2, "what loaded is still there")

        loader.load(page: 2)
        await settle()
        #expect(server.requested == [1, 2], "a failed page is not fetched again until retried")

        loader.retry()
        await settle()
        #expect(loader.failure == nil)
        #expect(loader.page?.count == 2)
        #expect(server.requested == [1, 2, 2], "the retry fetches only the page that failed")

        server.send([3, 4], total: 4, as: 2)
        await settle()
        #expect(loader.page?.count == 4)
    }

    @Test
    func `pages that fail together can all be retried`() async {
        let server = Server()
        let loader = await loaded(from: server, total: 4)  // page 1's cached copy
        loader.load(page: 2)
        await settle()

        // Page 1's fresh copy and page 2 both fail, so neither is lost to the other.
        server.fail(1)
        server.fail(2)
        await settle()
        #expect(loader.failure != nil)

        loader.retry()
        await settle()
        #expect(loader.failure == nil)
        #expect(server.requested == [1, 2, 1, 2], "both failed pages are fetched again")
    }
}
