### Changelog

**main**

- Added `StoryblokClient.stories(page:pageSize:resolveLevel:query:)` to retrieve multiple stories. It publishes the
  page asked for as a `Page<Story<Content>>`, sending its cached copy first and then the fresh one, as `story()` does.
- Added `StoriesQuery` for the endpoint's parameters, addressing your content's fields by key path for sorting and
  filter queries, and created inline with `StoriesQuery { … }`. The `@BlockLibrary` macro conforms each nested
  content struct to the new `QueryableContent` protocol that makes this possible, by attaching the new
  `@StoryblokContent(_:)` macro to it. Apply `@StoryblokContent(_:)` yourself to a content struct declared outside a
  block library.
- Added `Page<Element>`, a page of a paginated endpoint's elements: a collection carrying the `total`, page `number`,
  page `size` and `hasNextPage`. Join a later page onto earlier ones with `+`, which leaves out elements already
  present.
- Added the `StoryblokUI` library, whose `Stories` view produces rows for the stories matching a query, loads the
  next page as its last row appears, starts again when the query changes, and shows replaceable loading, empty and
  failure views. It also holds rich text rendering, moved from `RichTextView`.
- Deprecated the `RichTextView` library, whose rich text rendering is now part of `StoryblokUI`. The `RichTextView`
  product and module still work, re-exporting `StoryblokUI`, until the next major release. Depend on `StoryblokUI`
  and `import StoryblokUI` instead; nothing else changes.
- Added `URLSession.CachedDataTaskPublisher`, created with `cachedDataTaskPublisher(for:)`, which publishes the
  response the URL cache holds for a request and then the response the request loads.
- `Story` now conforms to `Identifiable` via its `id`, so stories can be passed directly to `List` and `ForEach`.

**1.0.0**

- BREAKING CHANGE: `StoryblokClient.Error` is now an enum with `api(message:underlyingError:)` and
  `decoding(_:)` cases, so that decoding failures distinguishable from failed requests.
- BREAKING CHANGE: `StoryblokClient.init(library:session:)` has been removed, instead pass the `configuration`, 
  `delegate` and `delegateQueue` you gave the session to `init(library:accessToken:...)`.
- Made `attributedString(baseFont:)` on `RichTextComposite` and `RichText.Text` public, so custom `RichTextViewDelegate` 
  implementations can render inline rich text content themselves.
- Widened the `swift-syntax` dependency to `"602.0.0" ..< "605.0.0"`. swift-syntax versions each `6xx` as a
  major, so the previous `from: "602.0.0"` capped it below 603.
- Fixed a redundant network fetch for every story each time the space's cache version changed.
- Fixed a 2–3s delay on every `StoryblokClient.story()` fetch on iOS: the cache probe it issues first was counted as a  
  failed request by the rate limiter when it missed, backing off the real fetch.
- The Rich Text View's default image renderer now falls back to an image's `title` when its `alt` is
  empty or whitespace-only, hides images that have neither from VoiceOver as decorative, and marks
  described images with the `isImage` accessibility trait.

**0.3.0**

- Renamed `Blok` to `Block` throughout the Rich Text View for consistency. A deprecated `Blok` typealias and `blok(_:)` 
  factory are provided for backward compatibility.
- Removed a redundant `Story` initializer.

**0.2.0**

- Initial release of the Storyblok Client
- Initial release of the Rich Text View
- Added JetNews sample app

**0.1.0**

- Initial release of the URLSession Extension
