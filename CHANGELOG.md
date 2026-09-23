### Changelog

**main**

- Widened the `swift-syntax` dependency to `"602.0.0" ..< "605.0.0"`. swift-syntax versions each `6xx` as a
  major, so the previous `from: "602.0.0"` capped it below 603.
- BREAKING CHANGE: `StoryblokClient.Error` is now an enum with `api(message:underlyingError:)` and
  `decoding(_:)` cases, so that decoding failures distinguishable from failed requests.
- Made `attributedString(baseFont:)` on `RichTextComposite` and `RichText.Text` public, so custom `RichTextViewDelegate` 
  implementations can render inline rich text content themselves.
- BREAKING CHANGE: `StoryblokClient.init(library:session:)` has been removed, instead pass the `configuration`, 
  `delegate` and `delegateQueue` you gave the session to `init(library:accessToken:...)`.
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
