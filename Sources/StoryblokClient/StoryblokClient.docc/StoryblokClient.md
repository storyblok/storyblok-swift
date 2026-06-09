# ``StoryblokClient``

A Swift client for Storyblok's [Content Delivery API](https://www.storyblok.com/docs/api/content-delivery/v2) built on top of [`URLSessionExtension`](https://storyblok.github.io/storyblok-swift/documentation/urlsessionextension).

With out-of-the-box support for reactive story fetching, automatic relation resolution, rich text parsing, and custom component decoding.

Read <doc:UserGuide> to get started.

## Topics

### Creating a client

- ``StoryblokClient``
- ``StoryblokClient/init(accessToken:version:region:language:fallbackLanguage:cv:requestsPerSecond:components:configuration:lenientJsonDecoding:)``
- ``StoryblokClient/init(session:components:lenientJsonDecoding:)``

### Fetching stories

- ``StoryblokClient/story(_:as:)-(String,_)``
- ``StoryblokClient/story(_:as:)-(UUID,_)``
- ``Story``
- ``StoryblokClient/Error``

### Defining blocks

- ``Block``

### Field types

- ``Field``
- ``Field/Link``
- ``Field/Asset``

### Rich text

- ``RichText``
- ``RichText/Mark``
- ``RichText/Composite``
- ``RichText/TextAlign``
