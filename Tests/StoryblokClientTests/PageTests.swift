import Testing
import Foundation
@testable import StoryblokClient

@Suite("Page")
struct PageTests {

    /// Story `number`, whose UUID is derived from the number so the same story can appear on two pages.
    private func story(_ number: Int) -> Story<QueryLibrary.Article> {
        Story(
            id: Int64(number),
            uuid: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", number))!,
            name: "Story \(number)",
            content: QueryLibrary.Article(title: "t\(number)"),
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

    private func page(_ numbers: [Int], number: Int = 1, total: Int?) -> Page<Story<QueryLibrary.Article>> {
        Page(numbers.map(story), number: number, size: 2, total: total)
    }

    @Test
    func `a page has a next page until the total is reached`() {
        let first = page([1, 2], total: 5)
        #expect(first.total == 5)
        #expect(first.number == 1)
        #expect(first.size == 2)
        #expect(first.hasNextPage)

        #expect(page([5], number: 3, total: 5).hasNextPage == false)
        #expect(page([3, 4], number: 2, total: 4).hasNextPage == false, "a full page can be the last")
    }

    @Test
    func `without a total, a full page is not taken as the last and a short one is`() {
        #expect(page([1, 2], total: nil).hasNextPage)
        #expect(page([3], number: 2, total: nil).hasNextPage == false)
        #expect(page([], total: nil).hasNextPage == false)
    }

    @Test
    func `joining a later page appends its stories and takes its number and next page`() {
        let joined = page([1, 2], total: 3) + page([3], number: 2, total: 3)

        #expect(joined.map(\.name) == ["Story 1", "Story 2", "Story 3"])
        #expect(joined.number == 2)
        #expect(joined.total == 3)
        #expect(joined.hasNextPage == false)
    }

    @Test
    func `a story already on an earlier page is left out of a later one`() {
        // Page 2 shifted by one, as when a story is published between the two requests.
        let joined = page([1, 2], total: 5) + page([2, 3], number: 2, total: 5)

        #expect(joined.map(\.name) == ["Story 1", "Story 2", "Story 3"])
        #expect(joined.hasNextPage, "four of five counted before duplicates are removed")
    }

    @Test
    func `joining onto an empty page gives the later page`() {
        let first = page([1, 2], total: 4)

        #expect([] + first == first)
    }

    @Test
    func `a page made from elements has no next page`() {
        let stories: Page<Story<QueryLibrary.Article>> = [story(1)]

        #expect(stories.count == 1)
        #expect(stories.number == 0)
        #expect(stories.hasNextPage == false)
    }

    struct Entry : Identifiable, Equatable {
        let id: Int
        let name: String
    }

    @Test
    func `holds any identifiable element, not only stories`() {
        // As a datasource's entries would page: identified by their own id.
        let first = Page([Entry(id: 1, name: "a"), Entry(id: 2, name: "b")], number: 1, size: 2, total: 3)
        let second = Page([Entry(id: 2, name: "b"), Entry(id: 3, name: "c")], number: 2, size: 2, total: 3)

        #expect((first + second).map(\.name) == ["a", "b", "c"])
    }
}
