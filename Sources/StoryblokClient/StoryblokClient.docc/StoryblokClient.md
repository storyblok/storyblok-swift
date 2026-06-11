# ``StoryblokClient``

A Swift client for Storyblok's [Content Delivery API](https://www.storyblok.com/docs/api/content-delivery/v2) built on top of ``/URLSessionExtension``.

With out-of-the-box support for reactive and `async` story fetching, automatic relation resolution, rich text parsing, and macro-driven component decoding.

## Overview

You describe your space's components once as a ``BlockLibrary`` — typically an `enum` annotated with the ``BlockLibrary()`` macro — and create a ``StoryblokClient`` generic over it. The library drives both how story content is decoded and which relations the client resolves.

```swift
@BlockLibrary
enum Content {
    case page(Page)
    case article(Article)
    case unknown

    struct Page: Decodable {
        let title: String
    }

    struct Article: Decodable {
        let headline: String
        let body: RichText<Content>
    }
}

let client = StoryblokClient(
    library: Content.self,
    accessToken: "YOUR_ACCESS_TOKEN",
    version: .draft
)

let story: Story<Content>? = try await client.story("articles/hello-world")
    .values
    .first { _ in true }
```

Read <doc:UserGuide> to get started.

## Topics

### Essentials

- <doc:UserGuide>

### Creating a client

- ``StoryblokClient``
- ``StoryblokClient/init(library:accessToken:version:region:language:fallbackLanguage:cv:requestsPerSecond:configuration:)``
- ``StoryblokClient/init(library:session:)``
- ``StoryblokClient/close()``

### Defining a block library

- ``BlockLibrary``
- ``BlockLibrary()``
- ``BlockLibrary/relations``

### Fetching stories

- ``StoryblokClient/story(_:resolveLevel:)-(String,_)``
- ``StoryblokClient/story(_:resolveLevel:)-(UUID,_)``
- ``StoryblokClient/Error``

### Stories

- ``Story``
- ``Alternate``
- ``TranslatedSlug``

### Field types

- ``Field``
- ``Field/Link``
- ``Field/Asset``

### Rich text

- ``RichText``
- ``RichTextComposite``
- ``RichText/Mark``
- ``RichText/TextAlign``
