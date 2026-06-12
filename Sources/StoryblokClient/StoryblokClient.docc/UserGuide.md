# Fetching Storyblok content with StoryblokClient

How to use ``StoryblokClient`` to fetch typed stories from the Storyblok [Content Delivery API](https://www.storyblok.com/docs/api/content-delivery/v2), with macro-driven component decoding and automatic relation resolution.

## Getting Started

### Add package dependency

Add the *storyblok-swift* repository as a package to your `Package.swift` file and specify `StoryblokClient` as a dependency of the target in which you wish to use it:

```swift
dependencies: [
    …
    .package(url: "https://github.com/storyblok/storyblok-swift.git", .upToNextMajor(from: "0.1.0"))
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

To create a client, pass your block library and access token to the ``StoryblokClient/init(library:accessToken:version:region:language:fallbackLanguage:cv:requestsPerSecond:configuration:)`` convenience initializer:

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

The ``StoryblokClient`` type provides two initializers. The convenience initializer ``StoryblokClient/init(library:accessToken:version:region:language:fallbackLanguage:cv:requestsPerSecond:configuration:)`` configures an internal [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) for you, while ``StoryblokClient/init(library:session:)`` lets you supply your own preconfigured session.

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

For more control, create the underlying [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) yourself and pass it to ``StoryblokClient/init(library:session:)``:

```swift
let configuration = URLSessionConfiguration.default
configuration.waitsForConnectivity = true

let session = URLSession(
    storyblok: .cdn(accessToken: "YOUR_ACCESS_TOKEN", version: .draft),
    configuration: configuration
)
let client = StoryblokClient(library: Content.self, session: session)
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
- `0` disables relation resolution. Optional `Story<T>` fields then decode as `nil` and non-optional `Story<T>` fields fail decoding — model relation fields as `String` to receive the raw UUIDs instead.

```swift
client.story("home", resolveLevel: 2)
```

### Circular relations

When relations form a cycle, resolution stops at the configured depth. How the boundary is handled depends on whether the field is optional:

- An **optional** relation (`Story<T>?` or `[Story<T>]?`) decodes as `nil` at the cycle boundary, breaking the cycle gracefully.
- A **non-optional** relation (`Story<T>`) throws a `DecodingError` when a cycle is detected.

Model fields that may participate in cycles as optional, or as a plain `String` (the UUID), to avoid decoding failures.

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
| Embedded Blok    | ``RichText/blok(_:)``         |
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

## Error handling

API errors and decoding failures are wrapped in ``StoryblokClient/Error``. Use Combine's [`catch`](https://developer.apple.com/documentation/combine/publisher/catch(_:)) operator to handle them:

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

## See Also

- [URLSessionExtension User Guide](doc:/URLSessionExtension/UserGuide)
- [Storyblok Content Delivery API reference](https://www.storyblok.com/docs/api/content-delivery/v2)
- [Resolving relations](https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-with-resolved-relations)
- [Storyblok rich text](https://www.storyblok.com/docs/richtext-field)
