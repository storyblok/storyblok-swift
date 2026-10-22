# ``StoryblokUI``

SwiftUI views for Storyblok stories and rich text.

With out-of-the-box support for lists that load the next page of stories as the user scrolls, and for rendering rich text as native SwiftUI views.

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
