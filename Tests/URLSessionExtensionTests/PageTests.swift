import Testing
import Foundation
@testable import URLSessionExtension

@Suite("Page")
struct PageTests {

    /// An element of a paginated endpoint, such as a datasource entry, identified by its id.
    struct Entry : Identifiable, Equatable {
        let id: Int
        var name: String { "Entry \(id)" }
    }

    private func page(_ ids: [Int], number: Int = 1, total: Int?) -> Page<Entry> {
        Page(ids.map(Entry.init), number: number, size: 2, total: total)
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
    func `joining a later page appends its elements and takes its number and next page`() {
        let joined = page([1, 2], total: 3) + page([3], number: 2, total: 3)

        #expect(joined.map(\.name) == ["Entry 1", "Entry 2", "Entry 3"])
        #expect(joined.number == 2)
        #expect(joined.total == 3)
        #expect(joined.hasNextPage == false)
    }

    @Test
    func `an element already on an earlier page is left out of a later one`() {
        // Page 2 shifted by one, as when content is published between the two requests.
        let joined = page([1, 2], total: 5) + page([2, 3], number: 2, total: 5)

        #expect(joined.map(\.name) == ["Entry 1", "Entry 2", "Entry 3"])
        #expect(joined.hasNextPage, "four of five counted before duplicates are removed")
    }

    @Test
    func `joining onto an empty page gives the later page`() {
        let empty: Page<Entry> = []
        let first = page([1, 2], total: 4)

        #expect(empty + first == first)
    }

    @Test
    func `a page made from elements has no next page`() {
        let entries: Page<Entry> = [Entry(id: 1)]

        #expect(entries.count == 1)
        #expect(entries.number == 0)
        #expect(entries.hasNextPage == false)
    }
}
