# Fetching Storyblok content with StoryblokClient

How to use ``StoryblokClient`` to fetch typed stories from the Storyblok [Content Delivery API](https://www.storyblok.com/docs/api/content-delivery/v2), with automatic relation resolution and polymorphic component decoding.

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

> Note: The `StoryblokClient` library is built on top of [`URLSessionExtension`](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension). You can learn more about the underlying session in the [URLSessionExtension User Guide](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension/userguide).

### Create a client

To create a client, use the ``StoryblokClient/init(accessToken:version:region:language:fallbackLanguage:cv:requestsPerSecond:components:configuration:lenientJsonDecoding:)`` convenience initializer:

```swift
let client = StoryblokClient(
    accessToken: "YOUR_ACCESS_TOKEN",
    version: .draft
)
```

API requests must be authenticated by providing an API access token. Learn more in the [Access Tokens concept](https://www.storyblok.com/docs/concepts/access-tokens).

### Fetch a story

``StoryblokClient/story(_:as:)-(String,_)`` returns a Combine [`Publisher`](https://developer.apple.com/documentation/combine/publisher) which may emit up to two values for a given request:

- The cached version of the story if one is available locally.
- The latest version from the API, unless it matches the cached version already emitted.

Stories can be fetched by slug or UUID:

```swift
// Fetch by slug
client.story("articles/hello-world")
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { story in print(story.name) }
    )
    .store(in: &cancellables)

// Fetch by UUID
client.story(UUID(uuidString: "bfea4895-8a19-4e82-ae1c-1c8f3e4b6f9c")!)
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { story in print(story.name) }
    )
    .store(in: &cancellables)
```

## Detailed Guide
---

## Creating a client

The ``StoryblokClient`` type provides two initializers. The [convenience initializer](doc:StoryblokClient/init(accessToken:version:region:language:fallbackLanguage:cv:requestsPerSecond:components:configuration:lenientJsonDecoding:)) configures an internal [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) for you, while the [session initializer](doc:StoryblokClient/init(session:components:lenientJsonDecoding:)) lets you supply your own preconfigured session.

### Simple configuration

Configuring default parameters for all requests is as simple as passing them to the convenience initializer:

```swift
let client = StoryblokClient(
    accessToken: "YOUR_ACCESS_TOKEN",
    version: .draft,
    region: .usa,
    language: "en",
    fallbackLanguage: "de",
    cv: "1706094649"
)
```

> Tip: These parameters map directly to the ones accepted by [`Api.cdn(...)`](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension/api/cdn(accesstoken:language:fallbacklanguage:version:cv:region:requestspersecond:)). Learn more in the [URLSessionExtension User Guide](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension/userguide).

### Advanced configuration

For more control, create the underlying [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession) yourself and pass it to ``StoryblokClient/init(session:components:lenientJsonDecoding:)``:

```swift
let configuration = URLSessionConfiguration.default
configuration.waitsForConnectivity = true

let session = URLSession(
    storyblok: .cdn(accessToken: "YOUR_ACCESS_TOKEN", version: .draft),
    configuration: configuration
)
let client = StoryblokClient(
    session: session,
    components: [Page.self, Article.self],
    lenientJsonDecoding: true
)
```

### Closing the client

When you're done using the client, call ``StoryblokClient/close()`` to release the resources held by the underlying session:

```swift
client.close()
```

## Registering custom blocks

Storyblok components are decoded into Swift types that conform to ``Block``. To use custom blocks, declare them and register them with the client:

```swift
struct Page: Block {
    static let component = "page"
    let _uid: String
    let component: String
    let title: String
}

struct Article: Block {
    static let component = "article"
    let _uid: String
    let component: String
    let headline: String
    let content: RichText
}

let client = StoryblokClient(
    accessToken: "YOUR_ACCESS_TOKEN",
    version: .draft,
    blocks: [Page.self, Article.self]
)
```

> Note: The ``Block/component`` value must match the component's technical name in Storyblok.

### Fetching typed stories

Once components are registered, if you know the type of component your story contains you can fetch stories typed to it:

```swift
client.story("home", as: Page.self)
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { story in print(story.content.title) }
    )
    .store(in: &cancellables)
```

### Unknown blocks

Blocks that are not registered will be decoded as ``UnknownBlock`` when reached via ``AnyBlock``. This allows your app to handle unrecognised blocks gracefully without causing decoding errors.

```swift
client.story("home") // defaults to Story<AnyBlock>
    .sink(
        receiveCompletion: { _ in },
        receiveValue: { story in
            if let page = story.content.wrapped as? Page {
                print(page.title)
            } else if story.content.wrapped is UnknownBlock {
                print("Unknown block: \(story.content.component)")
            }
        }
    )
    .store(in: &cancellables)
```

## Story relations

The client automatically resolves [story relations](https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-with-resolved-relations) based on the fields declared in ``Block/relations`` on your registered block types. When a block has a property of type ``Story``, the client will:

1. Include the appropriate `resolve_relations` query parameter in API requests.
2. Replace the referenced UUID string in the response with the matching object from the `rels` array.
3. Decode the resolved relation as a nested ``Story`` value.

```swift
struct FeaturedArticle: Block {
    static let component = "featured"
    static let relations: Set<String> = ["article"]
    let _uid: String
    let component: String
    let article: Story<Article>  // Automatically resolved
}

struct PopularArticles: Block {
    static let component = "popular"
    static let relations: Set<String> = ["articles"]
    let _uid: String
    let component: String
    let articles: [Story<Article>]  // Lists are also supported
}
```

> Important: Unlike the `storyblok-kotlin` client, relations are not inferred automatically from the type of your properties. You must declare them explicitly in ``Block/relations`` so the client knows which fields to include in the `resolve_relations` parameter.

> Tip: The maximum number of relations that can be resolved is 50 stories per request. This is a Storyblok API limitation.

## Rich text fields

Rich text content from Storyblok is decoded into the structured ``RichText`` enum hierarchy. Declare a ``RichText`` property on your block to decode rich text in a type-safe manner:

```swift
struct Article: Block {
    static let component = "article"
    let _uid: String
    let component: String
    let content: RichText
}
```

### Supported rich text nodes

| Node Type       | Case                        |
|-----------------|-----------------------------|
| Document        | ``RichText/document(_:)``   |
| Paragraph       | ``RichText/paragraph(_:)``  |
| Heading         | ``RichText/heading(_:)``    |
| Text            | ``RichText/text(_:)``       |
| Bold/Italic/etc | ``RichText/mark(_:)``       |
| Bullet List     | ``RichText/bulletList(_:)`` |
| Ordered List    | ``RichText/orderedList(_:)``|
| List Item       | ``RichText/listItem(_:)``   |
| Blockquote      | ``RichText/blockquote(_:)`` |
| Code Block      | ``RichText/codeBlock(_:)``  |
| Image           | ``RichText/image(_:)``      |
| Horizontal Rule | ``RichText/horizontalRule`` |
| Table           | ``RichText/table(_:)``      |
| Embedded Blok   | ``RichText/blok(_:)``       |
| Emoji           | ``RichText/emoji(_:)``      |
| Hard Break      | ``RichText/hardBreak(_:)``  |

### Traversing rich text

Composite rich text nodes conform to the ``RichText/Composite`` protocol, which provides a `flatten()` function to recursively yield all nested nodes:

```swift
if case let .document(document) = article.content {
    for case let .text(text) in document.flatten() {
        print(text.text)
    }
}
```

## Field types

Common Storyblok field types are provided as `Decodable` types for type-safe decoding:

### Link field

```swift
struct Page: Block {
    static let component = "page"
    let _uid: String
    let component: String
    let link: Field.Link
}

print(page.link.url ?? "")
print(page.link.linkType) // "url", "story", "email", etc.
```

### Asset field

```swift
struct Page: Block {
    static let component = "page"
    let _uid: String
    let component: String
    let image: Field.Asset
}

print(page.image.filename)
print(page.image.alt ?? "")
```

## Caching

The client leverages [`URLSessionExtension`](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension)'s caching for the configured [`URLSession`](https://developer.apple.com/documentation/foundation/urlsession). When fetching stories the client emits values using a *stale-while-revalidate* pattern:

1. The client first attempts to retrieve the story from cache (using [`.returnCacheDataDontLoad`](https://developer.apple.com/documentation/foundation/nsurlrequest/cachepolicy-swift.enum/returncachedatadontload)).
2. It then makes a network request to get the latest version.
3. Duplicates are filtered so the cached and fresh responses are only emitted once when identical.

## Error handling

API errors and decoding failures are wrapped in ``StoryblokClient/Error``. Use Combine's [`catch`](https://developer.apple.com/documentation/combine/publisher/catch(_:)) operator to handle them:

```swift
client.story("non-existent", as: Page.self)
    .catch { error -> Empty<Story<Page>, Never> in
        print("Failed to fetch story: \(error.localizedDescription)")
        return Empty<Story<Page>, Never>()
    }
    .sink(receiveValue: { story in /* handle story */ })
    .store(in: &cancellables)
```

## See Also

- [URLSessionExtension User Guide](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension/userguide)
- [Storyblok Content Delivery API reference](https://www.storyblok.com/docs/api/content-delivery/v2)
- [Resolving relations](https://www.storyblok.com/docs/api/content-delivery/v2/stories/examples/retrieving-stories-with-resolved-relations)
- [Storyblok rich text](https://www.storyblok.com/docs/richtext-field)
