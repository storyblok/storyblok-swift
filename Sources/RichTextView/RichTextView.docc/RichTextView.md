# ``RichTextView``

Render Storyblok rich text as native SwiftUI views.

`RichTextView` is a SwiftUI rendering layer for the ``/StoryblokClient/RichText`` type from ``/StoryblokClient``. Importing it makes a decoded `RichText` value conform to `View`, so you can drop rich text straight into a SwiftUI hierarchy and get native text, headings, lists, tables, images, code blocks, embedded component bloks, and more — with sensible built-in styling.

## Overview

Once you import `RichTextView`, any `RichText<Library>` whose `Library` is itself a `View` becomes renderable:

```swift
import SwiftUI
import StoryblokClient
import RichTextView

struct ArticleView: View {
    let content: RichText<Content>

    var body: some View {
        ScrollView {
            content
                .padding()
        }
        .onStoryLink { uuid, anchor in
            // navigate to the linked story
        }
    }
}
```

Each rich-text node renders with a built-in default view. To customize specific node types, supply a ``RichTextViewDelegate`` with ``RichTextView/SwiftUICore/View/richTextViewDelegate(_:)``. To handle taps on internal story links, use ``RichTextView/SwiftUICore/View/onStoryLink(_:)``.

Read <doc:UserGuide> to get started.

## Topics

### Essentials

- <doc:UserGuide>

### Rendering rich text

- ``RichTextView/StoryblokClient/RichText/body``

### Customizing node rendering

- ``RichTextViewDelegate``
- ``RichTextView/SwiftUICore/View/richTextViewDelegate(_:)``

### Handling story links

- ``RichTextView/SwiftUICore/View/onStoryLink(_:)``
- ``StoryLinkHandler``
