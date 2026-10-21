import Foundation
import Combine
import StoryblokClient

/// The pages behind a ``Stories`` view, and the stories they hold, joined in page order.
///
/// Held as a `StateObject`, so it lives as long as the view does, however many of its rows are on
/// screen: the pages, and the requests for further ones, outlast any one row.
@MainActor
final class StoriesLoader<Library : BlockLibrary, Content : QueryableContent> : ObservableObject {

    typealias PagePublisher = AnyPublisher<Page<Story<Content>>, StoryblokClient<Library>.Error>

    /// What a request asks for. A new value starts the stories again from page 1.
    struct Key : Hashable {
        let client: ObjectIdentifier
        let pageSize: Int
        let resolveLevel: Int
        let queryItems: [URLQueryItem]
    }

    /// The stories loaded so far, or `nil` until the first page arrives.
    @Published private(set) var page: Page<Story<Content>>?

    /// Why the last page that failed did, until it is retried.
    @Published private(set) var failure: StoryblokClient<Library>.Error?

    private var key: Key?
    private var fetch: ((_ page: Int) -> PagePublisher)?

    /// The latest copy of each page received, by number.
    private var pages: [Int: Page<Story<Content>>] = [:]

    /// The page that failed, so that `retry` can fetch it again.
    private var failed: Int?

    // One per page requested, so each is fetched once. Cancelled in deinit, which is not isolated
    // to the main actor.
    nonisolated(unsafe) private var tasks: [Int: Task<Void, Never>] = [:]

    // Created as a `StateObject`'s default value, outside the main actor.
    nonisolated init() {}

    deinit {
        tasks.values.forEach { $0.cancel() }
    }

    /// Loads page 1 of the stories `fetch` publishes, unless they are already what this is loading.
    ///
    /// Called while SwiftUI updates the view, so the fetch starts on the next turn of the main
    /// actor rather than changing the view in the middle of that update.
    func start(_ key: Key, _ fetch: @escaping (_ page: Int) -> PagePublisher) {
        guard key != self.key else { return }
        self.key = key
        self.fetch = fetch
        Task {
            // A later start has replaced this one.
            guard key == self.key else { return }
            self.reset()
            self.load(page: 1)
        }
    }

    /// Fetches page `number`, unless it has already been requested.
    func load(page number: Int) {
        guard tasks[number] == nil, let fetch else { return }

        tasks[number] = Task { [weak self] in
            do {
                for try await page in fetch(number).values {
                    guard !Task.isCancelled else { return }
                    self?.receive(page, as: number)
                }
            } catch let error as StoryblokClient<Library>.Error {
                guard !Task.isCancelled else { return }
                self?.failed = number
                self?.failure = error
            } catch {
                // Only cancellation reaches here, and a cancelled load reports nothing.
            }
        }
    }

    /// Fetches the page that failed again, showing what loaded until it arrives.
    func retry() {
        guard let failed else { return }
        self.failed = nil
        failure = nil
        tasks[failed] = nil
        load(page: failed)
    }

    /// Replaces the copy of page `number` and joins the pages again, so a fresh copy replaces its
    /// cached one in place even after later pages have arrived.
    private func receive(_ page: Page<Story<Content>>, as number: Int) {
        pages[number] = page
        self.page = pages.keys.sorted().map { pages[$0]! }.reduce(Page([]), +)
    }

    private func reset() {
        tasks.values.forEach { $0.cancel() }
        tasks = [:]
        pages = [:]
        failed = nil
        page = nil
        failure = nil
    }
}
