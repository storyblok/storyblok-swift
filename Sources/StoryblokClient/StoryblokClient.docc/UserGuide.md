# Fetching Storyblok content with StoryblokClient

How to use ``StoryblokClient`` to fetch typed stories from the Storyblok [Content Delivery API](https://www.storyblok.com/docs/api/content-delivery/v2), with macro-driven component decoding and automatic relation resolution.

## Getting Started

### Add package dependency

In an Xcode project, select **File** → **Add Package Dependencies…**, enter the following package URL into the search field, select **Add Package**, and add the `StoryblokClient` library to the target in which you wish to use it:

```
https://github.com/storyblok/storyblok-swift.git
```

Alternatively, in a Swift package, add the *storyblok-swift* repository as a package to your `Package.swift` file and specify `StoryblokClient` as a dependency of the target:

```swift
dependencies: [
    …
    .package(url: "https://github.com/storyblok/storyblok-swift.git", .upToNextMajor(from: "1.0.0"))
]
targets: [
    .target(
        …
        dependencies: [
            .product(name: "StoryblokClient", package: "storyblok-swift")
        ]
    )
]
```

> Note: The `StoryblokClient` library is built on top of ``/URLSessionExtension``. You can learn more about the underlying session in the [URLSessionExtension User Guide](doc:/URLSessionExtension/UserGuide).

### Define a block library

A ``BlockLibrary`` enumerates the Storyblok components your space uses. The easiest way to declare one is to apply the ``BlockLibrary()`` macro to an `enum`, with one case per component:

```swift
@BlockLibrary
enum Content {
    case page(Page)
    case article(Article)
    case unknown

    struct Page: Decodable {
        let title: String
        let body: [Content]
    }

    struct Article: Decodable {
        let headline: String
        let body: RichText<Content>
    }
}
```

The macro synthesizes the `Decodable` conformance, the ``BlockLibrary/relations`` string, and the `CodingKeys` the decoder needs. See <doc:UserGuide#Defining-a-block-library> for the full set of rules.

### Create a client

To create a client, pass your block library and access token to ``StoryblokClient/init(library:accessToken:version:region:language:fallbackLanguage:cv:requestsPerSecond:configuration:delegate:delegateQueue:)``:

```swift
let client = StoryblokClient(
    library: Content.self,
    accessToken: "YOUR_ACCESS_TOKEN",
    version: .draft
)
```

API requests must be authenticated by providing an API access token. Learn more in the [Access Tokens concept](https://www.storyblok.com/docs/concepts/access-tokens).

### Fetch a story

``StoryblokClient/story(_:resolveLevel:)-(String,_)`` returns a Combine [`Publisher`](https://developer.apple.com/documentation/combine/publisher) which may emit up to two values for a given request:

- The cached version of the story if one is available locally.
- The latest version from the API, unless it matches the cached version already emitted.

The decoded content type is inferred from the value you bind. Most often that is the block library itself, giving you a `Story<Content>` you can switch over:

```swift
client.story("articles/hello-world")
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { (story: Story<Content>) in
            if case let .article(article) = story.content {
                print(article.headline)
            }
        }
    )
    .store(in: &cancellables)
```

You can also consume the publisher with `async`/`await` through its [`values`](https://developer.apple.com/documentation/combine/publisher/values-1dm9r) sequence:

```swift
let story: Story<Content>? = try await client.story("articles/hello-world")
    .values
    .first { _ in true }
```

## Detailed Guide
---

## Defining a block library

The ``BlockLibrary()`` macro turns an `enum` into a polymorphic decoder keyed on the Storyblok `component` field. The following rules apply:

### Components as cases

Each case corresponds to a component. By default the case name must match the component's technical name in Storyblok:

```swift
@BlockLibrary
enum Content {
    case hero(Hero)        // matches component "hero"
    case article(Article)  // matches component "article"

    struct Hero: Decodable { let title: String }
    struct Article: Decodable { let headline: String }
}
```

### Nested struct content vs. labeled fields

A case may carry its fields in one of two ways:

- **A single unlabeled nested struct**, declared inside the enum, which decodes the entire content object. Every nested struct must have a matching case.
- **Labeled associated values**, which decode individual fields of the content object directly.

```swift
@BlockLibrary
enum Content {
    // Whole content object decoded into a nested struct
    case article(Article)

    // Individual fields decoded from the content object
    case header(altTitle: String, altSubtitle: String, altImage: Field.Asset)

    struct Article: Decodable {
        let headline: String
        let body: RichText<Content>
    }
}
```

Choose a nested struct for a component whose stories you query by their fields, such as a content type you list or search. The struct is the component's type, so a ``StoriesQuery`` can be typed to it and a ``Story`` can decode it: see <doc:UserGuide#Querying-a-component-by-its-fields>. Labeled values give a component no type of its own, so its fields can't be addressed by key path.

### Mapping component and field names

When a Swift identifier can't match the API name (for example a technical name containing a dash, or a field whose JSON key differs), provide a mapping enum:

- A top-level `CodingKeys` enum remaps **case names** to component technical names.
- A `<CaseName>CodingKeys` enum remaps a case's **labeled fields** to their JSON keys.

```swift
@BlockLibrary
enum Content {
    case header(altTitle: String, altSubtitle: String)

    enum HeaderCodingKeys: String, CodingKey {
        case altTitle = "alternativeTitle"
        case altSubtitle = "alternativeSubtitle"
    }
}
```

### Handling unknown components

Add a parameterless `case unknown` to act as a catch-all. Components not matched by any other case decode as `.unknown` instead of throwing, so your app handles new or unrecognised components gracefully:

```swift
@BlockLibrary
enum Content {
    case page(Page)
    case unknown   // any other component decodes here

    struct Page: Decodable { let title: String }
}
```

Without a `case unknown`, an unrecognised component causes a `DecodingError`.

### Manual conformance

The macro is optional. Any `Decodable` type can conform to ``BlockLibrary`` directly — useful when a story always contains a single component. Implement ``BlockLibrary/relations`` only if the type has relations to resolve (it defaults to an empty string):

```swift
struct PageContent: BlockLibrary {
    let component: String
    let title: String?
}
```

## Creating a client

The ``StoryblokClient`` type has a single initializer, ``StoryblokClient/init(library:accessToken:version:region:language:fallbackLanguage:cv:requestsPerSecond:configuration:delegate:delegateQueue:)``, which builds the [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) it uses. Pass it a `configuration`, a `delegate` and a `delegateQueue` to control that session.

### Simple configuration

Configuring default parameters for all requests is as simple as passing them to the convenience initializer:

```swift
let client = StoryblokClient(
    library: Content.self,
    accessToken: "YOUR_ACCESS_TOKEN",
    version: .draft,
    region: .usa,
    language: "en",
    fallbackLanguage: "de",
    cv: "1706094649"
)
```

> Tip: These parameters map directly to the ones accepted by [`Api.cdn(...)`](doc:/URLSessionExtension/Api/cdn(accessToken:language:fallbackLanguage:version:cv:region:requestsPerSecond:)). Learn more in the [URLSessionExtension User Guide](doc:/URLSessionExtension/UserGuide).

### Advanced configuration

The client creates the underlying [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession), you can customize the session's configuration, delegate, and delegate queue:

```swift
let configuration = URLSessionConfiguration.default
configuration.waitsForConnectivity = true

let client = StoryblokClient(
    library: Content.self,
    accessToken: "YOUR_ACCESS_TOKEN",
    version: .draft,
    configuration: configuration,
    delegate: myDelegate
)
```

### Closing the client

When you're done using the client, call ``StoryblokClient/close()`` to release the resources held by the underlying session:

```swift
client.close()
```

## Fetching stories

Stories can be fetched by slug or UUID:

```swift
// Fetch by slug
client.story("articles/hello-world")
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { (story: Story<Content>) in print(story.name) }
    )
    .store(in: &cancellables)

// Fetch by UUID
client.story(UUID(uuidString: "bfea4895-8a19-4e82-ae1c-1c8f3e4b6f9c")!)
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { (story: Story<Content>) in print(story.name) }
    )
    .store(in: &cancellables)
```

### Choosing the content type

The `Content` generic of the returned ``Story`` is inferred from how you bind the result. Binding to the block library lets you switch over every component:

```swift
let story: Story<Content>? = try await client.story("home").values.first { _ in true }
if case let .page(page) = story?.content {
    print(page.title)
}
```

When you know a story always contains one specific component, you can bind directly to a nested block struct (or any `Decodable` type matching the content shape) to skip the `switch`:

```swift
let story: Story<Content.Page>? = try await client.story("home").values.first { _ in true }
print(story?.content.title ?? "")
```

## Fetching multiple stories

``StoryblokClient/stories(page:pageSize:resolveLevel:query:)`` retrieves the stories matching a query from the [stories endpoint](https://www.storyblok.com/docs/api/content-delivery/v2/stories/retrieve-multiple-stories), one page at a time. Like `story`, it publishes the copy the URL cache holds, if any, then the latest one from the API:

```swift
client.stories(page: 1) { (query: inout StoriesQuery<Content.Article>) in
    query.startsWith = "articles/"
}
.sink(
    receiveCompletion: { _ in },
    receiveValue: { (page: Page<Story<Content.Article>>) in
        for story in page { print(story.content.headline) }
    }
)
.store(in: &cancellables)
```

The query's type names the content type. A query typed to one of your content structs, `Content.Article` here, sends its component as `content_type` and so asks for those stories only. A query typed to the whole block library asks for stories of every type.

### Building a query

``StoriesQuery`` has a property or method for each of the endpoint's parameters. Fields of your own content are addressed by key path, so a misspelled field doesn't compile, and a filter offers only the operations the field's type supports:

```swift
client.stories { (query: inout StoriesQuery<Content.Article>) in
    query.searchTerm = "space"
    query.sort(by: \.headline)
    query.sort(by: .publishedAt, .descending)
    query.filter {
        $0.headline.like("*Mars*")
    }
}
```

The ``BlockLibrary()`` macro makes this possible by conforming each nested content struct to ``QueryableContent``, which supplies the component's technical name and the name Storyblok knows each field by. For a content struct declared outside a block library, apply ``StoryblokContent(_:)`` with the component's technical name yourself.

For a parameter that has no entry point, such as a filter on a nested field, add it as written with ``StoriesQuery/parameter(_:_:)``:

```swift
client.stories { (query: inout StoriesQuery<Content.Article>) in
    query.parameter("filter_query[seo.description][is]", "not_empty")
}
```

### Querying a component by its fields

A query is typed to a component's struct, so only a component modelled with a nested struct can be queried by its fields. One modelled with labeled values has no type to name, and Swift has no key paths into an enum case's values. To query it by its fields, model it with a nested struct:

```swift
@BlockLibrary
enum Content {
    // Before: case header(altTitle: String, altSubtitle: String)
    case header(Header)

    struct Header: Decodable {
        let altTitle: String
        let altSubtitle: String
    }
}

client.stories { (query: inout StoriesQuery<Content.Header>) in
    query.filter {
        $0.altTitle.like("*news*")
    }
}
```

Code that switches over the library then reads the struct, `case let .header(header)`, in place of the values, `case let .header(altTitle, altSubtitle)`.

Alternatively, a query typed to the whole block library can still ask for that component's stories, naming its type and fields as the API does:

```swift
client.stories { (query: inout StoriesQuery<Content>) in
    query.parameter("content_type", "header")
    query.parameter("filter_query[altTitle][like]", "*news*")
}
```

### Paging through the results

Each value is a ``/URLSessionExtension/Page``: a collection of that page's stories, along with the ``/URLSessionExtension/Page/total`` the API reports and whether there is a page after it. Fetch the next page with `page + 1` while ``/URLSessionExtension/Page/hasNextPage`` is `true`, and join each page onto the ones before it with `+`, which leaves out any story already on an earlier page:

```swift
var articles: Page<Story<Content.Article>> = []
var number = 1
repeat {
    let stories: AnyPublisher<Page<Story<Content.Article>>, _> = client.stories(page: number)
    var page: Page<Story<Content.Article>> = []
    for try await copy in stories.values { page = copy }  // the latest copy arrives last
    articles = articles + page
    number += 1
} while articles.hasNextPage
```

The page size defaults to 25 and can be raised to 100 with `pageSize`.

> Tip: To show the stories in a SwiftUI list that fetches the next page as the user scrolls, use the `Stories` view from the [StoryblokUI](https://storyblok.github.io/storyblok-swift/documentation/storyblokui) library.

## Story relations

The client automatically resolves [story relations](https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-with-resolved-relations) declared on your block library. Whenever a case (or one of its nested struct fields) has a ``Story``-typed associated value, the macro records it in ``BlockLibrary/relations``, and the client will:

1. Include the appropriate `resolve_relations` query parameter in API requests.
2. Replace the referenced UUID string in the response with the matching object from the `rels` array.
3. Decode the resolved relation as a nested ``Story`` value.

```swift
@BlockLibrary
enum Content {
    case featured(article: Story<Content>)      // resolved automatically
    case popular(articles: [Story<Content>])    // lists are also supported
    case article(Article)

    struct Article: Decodable {
        let headline: String
        let author: Story<Content>               // nested-struct relations too
    }
}
// Content.relations == "article.author,featured.article,popular.articles"
```

> Important: A `Story<T>` relation field's type argument `T` must be the enclosing block library `enum` or one of its nested structs, so the macro can discover its relation fields.

### Controlling resolution depth

The `resolveLevel` parameter of ``StoryblokClient/story(_:resolveLevel:)-(String,_)`` controls how deeply relations are followed:

- `1` (the default) resolves direct relations.
- Higher values resolve relations of relations.
- `0` disables relation resolution. Optional `Story<T>` fields then decode as `nil` and non-optional `Story<T>` fields fail decoding — model relation fields as `UUID` (or `String`) to receive the raw UUIDs instead.

```swift
client.story("home", resolveLevel: 2)
```

### Circular relations

When relations form a cycle, resolution stops at the configured depth. How the boundary is handled depends on whether the field is optional:

- An **optional** relation (`Story<T>?` or `[Story<T>]?`) decodes as `nil` at the cycle boundary, breaking the cycle gracefully.
- A **non-optional** relation (`Story<T>`) throws a `DecodingError` when a cycle is detected.

Model fields that may participate in cycles as optional, or as a `UUID` (or `String`), to avoid decoding failures.

> Tip: The maximum number of relations that can be resolved is 50 stories per request. This is a Storyblok API limitation.

## Rich text fields

Rich text content from Storyblok is decoded into the structured ``RichText`` enum. ``RichText`` is generic over your block library so that embedded component blocks decode into the same types as the rest of your content. Declare a `RichText<YourLibrary>` property on a block to decode rich text in a type-safe manner:

```swift
@BlockLibrary
enum Content {
    case article(Article)

    struct Article: Decodable {
        let body: RichText<Content>
    }
}
```

### Supported rich text nodes

| Node Type        | Case                          |
|------------------|-------------------------------|
| Document         | ``RichText/document(_:)``     |
| Paragraph        | ``RichText/paragraph(_:)``    |
| Heading          | ``RichText/heading(_:)``      |
| Text             | ``RichText/text(_:)``         |
| Mark (formatting)| ``RichText/mark(_:)``         |
| Bullet List      | ``RichText/bulletList(_:)``   |
| Ordered List     | ``RichText/orderedList(_:)``  |
| List Item        | ``RichText/listItem(_:)``     |
| Blockquote       | ``RichText/blockquote(_:)``   |
| Code Block       | ``RichText/codeBlock(_:)``    |
| Image            | ``RichText/image(_:)``        |
| Horizontal Rule  | ``RichText/horizontalRule``   |
| Table            | ``RichText/table(_:)``        |
| Table Row        | ``RichText/tableRow(_:)``     |
| Table Header     | ``RichText/tableHeader(_:)``  |
| Table Cell       | ``RichText/tableCell(_:)``    |
| Embedded Block   | ``RichText/block(_:)``        |
| Emoji            | ``RichText/emoji(_:)``        |
| Hard Break       | ``RichText/hardBreak(_:)``    |
| Unknown          | ``RichText/unknown(type:)``   |

Nodes whose `type` is not recognised decode as ``RichText/unknown(type:)`` rather than failing.

### Text marks

Inline formatting on a ``RichText/Text`` node is represented by the ``RichText/Mark`` enum, covering bold, italic, underline, strike, code, subscript, superscript, links (``RichText/Mark/link(_:)``), and color styling (``RichText/Mark/textStyle(color:)`` and ``RichText/Mark/highlight(color:)``). Unrecognised marks decode as ``RichText/Mark/unknown(type:)``.

### Traversing rich text

Composite rich text nodes conform to the ``RichTextComposite`` protocol, which provides a `flatten()` function to recursively yield all nested leaf nodes:

```swift
if case let .document(document) = article.body {
    for case let .text(text) in document.flatten() {
        print(text.text)
    }
}
```

> Tip: To render rich text as native SwiftUI views, use the [StoryblokUI](https://storyblok.github.io/storyblok-swift/documentation/storyblokui/renderingrichtext) library, which makes a `RichText` value a `View`.

## Field types

Common Storyblok field types are provided as `Decodable` values. ``Field`` is an enum that dispatches on the `fieldtype` JSON field, exposing ``Field/Link`` and ``Field/Asset`` cases (plus ``Field/unknown(fieldType:)`` for field types this client doesn't model). You can decode a property as ``Field`` when its type varies, or as the concrete ``Field/Link`` / ``Field/Asset`` struct when it is fixed.

### Link field

```swift
@BlockLibrary
enum Content {
    case page(Page)

    struct Page: Decodable {
        let link: Field.Link
    }
}

print(page.link.url ?? "")
print(page.link.linkType) // "url", "story", "email", or "asset"
```

### Asset field

```swift
@BlockLibrary
enum Content {
    case page(Page)

    struct Page: Decodable {
        let image: Field.Asset
    }
}

print(page.image.filename)
print(page.image.alt ?? "")
```

## Caching

The client leverages ``/URLSessionExtension``'s caching for the configured [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession). When fetching stories the client emits values using a *stale-while-revalidate* pattern:

1. The client first attempts to retrieve the story from cache (using [`.returnCacheDataDontLoad`](https://developer.apple.com/documentation/foundation/nsurlrequest/cachepolicy-swift.enum/returncachedatadontload)).
2. It then makes a network request to get the latest version, retrying transient failures.
3. Duplicates are filtered so the cached and fresh responses are only emitted once when identical.

Stories and pages of stories are both fetched this way, through ``/URLSessionExtension``'s ``/URLSessionExtension/Foundation/URLSession/CachedDataTaskPublisher``, which you can also use directly for requests the client does not cover.

## Error handling

API errors and decoding failures are reported as ``StoryblokClient/Error``. Use Combine's [`catch`](https://developer.apple.com/documentation/combine/publisher/catch(_:)) operator to handle them:

```swift
client.story("non-existent")
    .catch { error -> Empty<Story<Content>, Never> in
        print("Failed to fetch story: \(error.localizedDescription)")
        return Empty<Story<Content>, Never>()
    }
    .sink(receiveValue: { story in /* handle story */ })
    .store(in: &cancellables)
```

When consuming the publisher with `async`/`await`, the same error is thrown from the `values` sequence and can be caught with `do`/`catch`.

The error's case suggests how to respond:

- ``StoryblokClient/Error/api(message:underlyingError:)`` — the request failed. Transient failures (`5xx` and `429`) have already been retried up to three times, so rather than retrying again, consider alerting the user and offering a manual retry.
- ``StoryblokClient/Error/decoding(_:)`` — the content does not match the types it was decoded into, which a retry cannot change. Consider failing loudly during development, and reporting to a crash reporting service in production.

```swift
.catch { error -> Empty<Story<Content>, Never> in
    switch error {
        case let .api(message, _):
            // Already retried by the client — prompt the user to retry manually.
            showRetryBanner(message: message)
        case let .decoding(error):
            // TODO: report to a crash reporting service in production
            fatalError("Content does not match the block library: \(error)")
    }
    return Empty<Story<Content>, Never>()
}
```

## See Also

- [URLSessionExtension User Guide](doc:/URLSessionExtension/UserGuide)
- [Storyblok Content Delivery API reference](https://www.storyblok.com/docs/api/content-delivery/v2)
- [Resolving relations](https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-with-resolved-relations)
- [Storyblok rich text](https://www.storyblok.com/docs/richtext-field)
