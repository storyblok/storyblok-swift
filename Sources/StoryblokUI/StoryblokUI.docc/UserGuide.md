# Showing paged stories with StoryblokUI

How to show the stories matching a query in a SwiftUI list that loads the next page as the user scrolls, change the query, and replace the loading, empty and failure views.

## Getting Started

### Add package dependency

In an Xcode project, select **File** → **Add Package Dependencies…**, enter the following package URL into the search field, select **Add Package**, and add the `StoryblokUI` library to the target in which you wish to use it:

```
https://github.com/storyblok/storyblok-swift.git
```

Alternatively, in a Swift package, add the *storyblok-swift* repository as a package to your `Package.swift` file and specify `StoryblokUI` as a dependency of the target:

```swift
dependencies: [
    …
    .package(url: "https://github.com/storyblok/storyblok-swift.git", .upToNextMajor(from: "1.0.0"))
]
targets: [
    .target(
        …
        dependencies: [
            .product(name: "StoryblokUI", package: "storyblok-swift")
        ]
    )
]
```

> Note: `StoryblokUI` builds on [StoryblokClient](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient). See the [StoryblokClient User Guide](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/userguide) for how to define a block library and create a client.

### Show the stories

Give ``Stories`` a client, the query, and the row for one story, and put it in a lazy container:

```swift
List {
    Stories(client: client, query: StoriesQuery<Content.Article> { $0.startsWith = "articles/" }) { story in
        ArticleRow(story)
    }
}
```

The query is a [`StoriesQuery`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/storiesquery) value. Its type names the content type, `Content.Article` here, which fixes the component the query addresses, and `StoriesQuery { … }` configures it where it is passed. To show stories of every type, type the query to your whole block library.

`Stories` fetches each page with [`stories(page:pageSize:resolveLevel:query:)`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/storyblokclient/stories(page:pagesize:resolvelevel:query:)) and keeps what loads for as long as it is in the view hierarchy, so the view using it holds no state for it. As that publisher does, it shows a page the URL cache holds at once, then updates it when the fresh copy arrives.

### Choose a lazy container

`Stories` produces rows, as `ForEach` does, so it can sit in a `List`, a `Section`, or a `LazyVStack` in a `ScrollView`, alongside any other rows:

```swift
ScrollView {
    LazyVStack(alignment: .leading) {
        FeaturedArticle()
        Stories(client: client, query: StoriesQuery<Content.Article>()) { story in
            ArticleRow(story)
        }
    }
}
```

> Important: Use a lazy container: `List`, or a `LazyVStack` or `LazyVGrid`. These build rows only as they come into view, which is what tells `Stories` the user has reached the last story. A plain `VStack` builds every row at once, so the last row appears immediately and every page loads in turn.

## How the next page loads

When the row showing the last story appears, `Stories` fetches the next page. When that page arrives, its stories are added after the others, and the row showing the new last story fetches the page after it once it too comes into view. This stops when there are no more pages.

A few properties of this follow:

- Each page is fetched once, however often the last row appears — for example as the user scrolls it away and back.
- When the stories loaded so far don't fill the screen, the last row is on screen as soon as it is built, so the next page loads straight away, and so on until the screen is full or every story has loaded.
- The last row also fetches the next page when a fresh copy of a page reveals one that its cached copy did not, even if that row is already on screen.
- A fresh copy of a page replaces its cached copy in place, even when later pages have already arrived.
- A story already on an earlier page is left out of a later one, as page-number paging shifts when stories are published between requests.

## Change the query

A different query value starts the stories again from page 1. To search as the user types, debounce the term into state and build the query from it:

```swift
@State private var text = ""
@State private var term = ""

var body: some View {
    List {
        Stories(client: client, query: StoriesQuery<Content.Article> { $0.searchTerm = term.isEmpty ? nil : term }) { story in
            ArticleRow(story)
        }
    }
    .searchable(text: $text)
    .task(id: text) {
        do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
        term = text
    }
}
```

The page size and relation depth are part of the request too: changing `pageSize` or `resolveLevel` also starts again from page 1.

## Replace the loading, empty and failure views

After the rows, `Stories` shows one of three views:

- `loading`, while the first page loads and while more pages are to come. It defaults to a progress indicator.
- `empty`, when the query matched no stories. It defaults to a short message.
- `failure`, when a page failed to load. It defaults to the error's description and a Retry button.

Pass your own as trailing closures:

```swift
Stories(client: client, query: query) { story in
    ArticleRow(story)
} empty: {
    ContentUnavailableView.search(text: term)
} failure: { error, retry in
    ContentUnavailableView {
        Label("Couldn't load articles", systemImage: "exclamationmark.triangle")
    } actions: {
        Button("Retry", action: retry)
    }
}
```

The `failure` closure receives the client's [`StoryblokClient.Error`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/storyblokclient/error) as `any Error`; cast it to tell a failed request from content that does not match your types. A failure keeps the stories that loaded on screen, and `retry` fetches the page that failed again.

## Where the stories are kept

`Stories` keeps its stories, and the requests for further pages, for as long as it stays in the view hierarchy, however many of its rows are on screen. Taking it out — closing a search, say — cancels any page still loading. Showing it again loads page 1 again, from the URL cache when it holds the page.

To use the stories outside a list, call [`stories(page:pageSize:resolveLevel:query:)`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/storyblokclient/stories(page:pagesize:resolvelevel:query:)) yourself for each page you need: it publishes the page as a [`Page`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/page), which says whether there is another, and joins onto the pages before it with `+`.

## See Also

- <doc:RenderingRichText>
- [StoryblokClient User Guide](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/userguide)
- [Retrieve multiple stories](https://www.storyblok.com/docs/api/content-delivery/v2/stories/retrieve-multiple-stories)
- [JetNews sample](https://github.com/storyblok/storyblok-swift/tree/main/Samples/JetNews)
