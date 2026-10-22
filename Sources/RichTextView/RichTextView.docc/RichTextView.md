# ``RichTextView``

Deprecated: rich text rendering is now part of StoryblokUI.

## Overview

The `RichTextView` library has moved into [StoryblokUI](https://storyblok.github.io/storyblok-swift/documentation/storyblokui), alongside its other SwiftUI views. This module now only re-exports `StoryblokUI`, so existing code keeps working, and it will be removed in the next major release.

To move, depend on the `StoryblokUI` product in place of `RichTextView`, and write `import StoryblokUI` in place of `import RichTextView`. Nothing else changes.

See [Rendering rich text](https://storyblok.github.io/storyblok-swift/documentation/storyblokui/renderingrichtext) for how to use it.
