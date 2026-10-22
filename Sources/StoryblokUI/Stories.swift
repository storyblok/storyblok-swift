import SwiftUI
import StoryblokClient

/// Rows for the stories matching a query, which load the next page as the user scrolls to the end
/// of the ones loaded.
///
/// `Stories` produces rows as `ForEach` does, so put it in a lazy container of your own — `List`,
/// or a `LazyVStack` in a `ScrollView` — alongside anything else the container shows:
///
/// ```swift
/// List {
///     Stories(client: client, query: StoriesQuery<Content.Article> { $0.startsWith = "articles/" }) { story in
///         ArticleRow(story)
///     }
/// }
/// ```
///
/// It fetches page 1 with [`stories(page:pageSize:resolveLevel:query:)`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/storyblokclient/stories(page:pagesize:resolvelevel:query:))
/// and keeps what loads for as long as it is in the view hierarchy, however many of its rows are
/// on screen, so you hold no state for it. As the row showing the last story appears, it fetches
/// the next page. When `query` changes, it starts again from page 1.
///
/// After the rows comes one of three views, each of which you can replace:
/// - `loading`, while the first page loads and while there are more pages to come;
/// - `empty`, when the query matched no stories;
/// - `failure`, when a page failed to load, with a `retry` action that fetches that page again.
public struct Stories<Library : BlockLibrary, Content : QueryableContent, Row : View, Loading : View, Empty : View, Failure : View> : View {

    private let row: (Story<Content>) -> Row
    private let loading: () -> Loading
    private let empty: () -> Empty
    private let failure: (_ error: any Error, _ retry: @escaping () -> Void) -> Failure

    private var request: Request

    /// Creates rows for the stories matching `query`.
    ///
    /// - Parameters:
    ///   - client: The client to load the stories with.
    ///   - pageSize: Stories per page, as for [`stories(page:pageSize:resolveLevel:query:)`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/storyblokclient/stories(page:pagesize:resolvelevel:query:)).
    ///   - resolveLevel: How deeply nested relations are resolved, as for
    ///     [`stories(page:pageSize:resolveLevel:query:)`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/storyblokclient/stories(page:pagesize:resolvelevel:query:)).
    ///   - query: The stories to show. A different value starts them again from page 1.
    ///   - row: The row for one story.
    ///   - loading: Shown after the rows while a page is loading or more are to come. Defaults to a
    ///     progress indicator.
    ///   - empty: Shown when the query matched no stories. Defaults to a short message.
    ///   - failure: Shown when a page failed to load, given the error — the client's
    ///     [`StoryblokClient.Error`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/storyblokclient/error) — and an action that retries. Defaults to the
    ///     error's description and a Retry button.
    public init(
        client: StoryblokClient<Library>,
        pageSize: Int = 25,
        resolveLevel: Int = 1,
        query: StoriesQuery<Content> = StoriesQuery(),
        @ViewBuilder row: @escaping (Story<Content>) -> Row,
        @ViewBuilder loading: @escaping () -> Loading = {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding()
        },
        @ViewBuilder empty: @escaping () -> Empty = {
            Text("No stories")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
        },
        @ViewBuilder failure: @escaping (_ error: any Error, _ retry: @escaping () -> Void) -> Failure = { error, retry in
            VStack(spacing: 8) {
                Text(error.localizedDescription)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry", action: retry)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
    ) {
        self.row = row
        self.loading = loading
        self.empty = empty
        self.failure = failure
        self.request = Request(
            key: .init(
                client: ObjectIdentifier(client),
                pageSize: pageSize,
                resolveLevel: resolveLevel,
                queryItems: query.queryItems
            ),
            fetch: { page in client.stories(page: page, pageSize: pageSize, resolveLevel: resolveLevel) { $0 = query } }
        )
    }

    public var body: some View {
        let loader = request.loader

        ForEach(loader.page ?? []) { story in
            row(story)
                // Keyed on the next page rather than run once on appearance: a fresh copy of a page
                // can reveal a next page while the last row is already on screen.
                .task(id: nextPage(after: story, in: loader.page)) {
                    if let next = nextPage(after: story, in: loader.page) { loader.load(page: next) }
                }
        }

        if let error = loader.failure {
            failure(error, loader.retry)
        } else if let page = loader.page {
            if page.hasNextPage {
                loading()
            } else if page.isEmpty {
                empty()
            }
        } else {
            loading()
        }
    }

    /// The page to load when `story` appears: the next one when it is the last story loaded and
    /// another page is to come, and otherwise none.
    private func nextPage(after story: Story<Content>, in page: Page<Story<Content>>?) -> Int? {
        guard let page, page.hasNextPage, story.id == page.last?.id else { return nil }
        return page.number + 1
    }

    /// Keeps the loader in step with the arguments the view was created with.
    ///
    /// SwiftUI calls `update()` before each `body`, which is how a view that produces only rows
    /// notices that its query changed: it has no container of its own to hang `onChange` on.
    private struct Request : DynamicProperty {
        @StateObject var loader: StoriesLoader<Library, Content>

        let key: StoriesLoader<Library, Content>.Key
        let fetch: (_ page: Int) -> StoriesLoader<Library, Content>.PagePublisher

        // Written out because creating a `StateObject` is main-actor isolated in newer SDKs, which a
        // memberwise initializer, being nonisolated, cannot be. `Stories` creates this on the main
        // actor, as a view.
        @MainActor
        init(key: StoriesLoader<Library, Content>.Key, fetch: @escaping (_ page: Int) -> StoriesLoader<Library, Content>.PagePublisher) {
            self._loader = StateObject(wrappedValue: StoriesLoader())
            self.key = key
            self.fetch = fetch
        }

        // SwiftUI updates a view's properties on the main thread, as it evaluates `body`, so handing
        // this property to a main-actor closure never takes it to another thread.
        nonisolated func update() {
            nonisolated(unsafe) let request = self
            MainActor.assumeIsolated { request.loader.start(request.key, request.fetch) }
        }
    }
}
