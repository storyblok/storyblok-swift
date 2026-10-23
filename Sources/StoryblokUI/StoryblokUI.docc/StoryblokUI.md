# ``StoryblokUI``

SwiftUI views for Storyblok stories and rich text.

Easily render stories and rich text, with sensible defaults that you can customize.

``Stories`` renders the stories matching a query, loading the next page as the user scrolls, and a decoded `RichText` value renders as native SwiftUI views.

Read <doc:UserGuide> and <doc:RenderingRichText> to get started.

## Topics

### Essentials

- <doc:UserGuide>
- <doc:RenderingRichText>

### Rendering stories

- ``Stories``
- ``Stories/init(client:pageSize:resolveLevel:query:row:loading:empty:failure:)``

### Rendering rich text

- ``StoryblokUI/StoryblokClient/RichText/body``
- ``RichTextViewDelegate``
- ``StoryblokUI/SwiftUICore/View/richTextViewDelegate(_:)``
- ``StoryblokUI/SwiftUICore/View/onStoryLink(_:)``
- ``StoryLinkHandler``
