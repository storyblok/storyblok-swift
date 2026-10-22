import Foundation

/// A page of a paginated endpoint's elements, such as the page
/// ``Foundation/URLSession/pagePublisher(for:page:perPage:elements:)`` publishes.
///
/// The Content Delivery and Management APIs page the same way, so a `Page` can hold any of their
/// lists, such as stories, assets or datasource entries.
///
/// A `Page` holds the elements of page ``number`` and says whether there is a page after it, so
/// the next page to fetch is `number + 1` while ``hasNextPage`` is `true`. Join a later page onto
/// the ones before it with ``+(_:_:)``, which leaves out the elements already present.
public struct Page<Element> {

    private var items: [Element]

    /// The total number of elements matching the request, as the endpoint's `total` header reports
    /// it, or `nil` when the response carried none or the page was not fetched.
    public let total: Int?

    /// The number of the page, counting from 1 — for pages joined with ``+(_:_:)``, of the last
    /// one — or 0 for a page that was not fetched.
    public let number: Int

    /// The elements per page the request asked for, sent as `per_page`, or 0 for a page that was
    /// not fetched.
    public let size: Int

    /// Whether there is a page after ``number`` to fetch.
    ///
    /// It follows the endpoint's `total` when it gave one, and otherwise whether the page came
    /// back short, since no page but the last can be.
    public let hasNextPage: Bool

    /// Page `number` of an endpoint, holding `elements` as it returned them.
    package init(_ elements: [Element], number: Int, size: Int, total: Int?) {
        self.items = elements
        self.total = total
        self.number = number
        self.size = size
        self.hasNextPage = total.map { (number - 1) * size + elements.count < $0 } ?? (elements.count == size)
    }

    /// A page of the given elements, which has no next page.
    public init<S : Sequence>(_ elements: S) where S.Element == Element {
        self.items = Array(elements)
        self.total = nil
        self.number = 0
        self.size = 0
        self.hasNextPage = false
    }

    private init(items: [Element], following page: Page) {
        self.items = items
        self.total = page.total
        self.number = page.number
        self.size = page.size
        self.hasNextPage = page.hasNextPage
    }
}

extension Page where Element : Identifiable {

    /// The elements of `lhs` followed by those of `rhs`, a later page, with ``number``, ``total``
    /// and ``hasNextPage`` taken from `rhs`.
    ///
    /// An element of `rhs` already in `lhs` is left out: page-number paging shifts when content is
    /// published between requests, so an element can turn up on two pages.
    public static func + (lhs: Page, rhs: Page) -> Page {
        var seen = Set(lhs.items.map(\.id))
        return Page(items: lhs.items + rhs.items.filter { seen.insert($0.id).inserted }, following: rhs)
    }
}

// MARK: - Collection

extension Page : RandomAccessCollection {
    public var startIndex: Int { items.startIndex }
    public var endIndex: Int { items.endIndex }
    public subscript(position: Int) -> Element { items[position] }
}

extension Page : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}

extension Page : Equatable where Element : Equatable {}

extension Page : Hashable where Element : Hashable {}

extension Page : Sendable where Element : Sendable {}
