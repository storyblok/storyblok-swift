# ``StoryblokUI``

SwiftUI views for Storyblok stories and rich text.

``Stories`` shows the stories matching a query as list rows that load the next page as the user scrolls, and a decoded `RichText` value renders as native SwiftUI views.

Read <doc:UserGuide> and <doc:RenderingRichText> to get started.

## Topics

### Essentials

- <doc:UserGuide>
- <doc:RenderingRichText>

### Showing stories

- ``Stories``
- ``Stories/init(client:pageSize:resolveLevel:query:row:loading:empty:failure:)``

### Rendering rich text

- ``StoryblokUI/StoryblokClient/RichText/body``

### Customizing rich text rendering

- ``RichTextViewDelegate``
- ``StoryblokUI/SwiftUICore/View/richTextViewDelegate(_:)``

### Handling story links

- ``StoryblokUI/SwiftUICore/View/onStoryLink(_:)``
- ``StoryLinkHandler``
