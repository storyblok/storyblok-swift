# ``StoryblokUI``

SwiftUI views for Storyblok content: lists of stories that load the next page as the user scrolls, and rich text rendered as native views.

## Overview

``Stories`` produces rows for the stories matching a query, the way `ForEach` does, so you put it in a `List` or in a `LazyVStack` of your own. It fetches the stories a page at a time with [StoryblokClient](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient)'s [`stories(page:pageSize:resolveLevel:query:)`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/storyblokclient/stories(page:pagesize:resolvelevel:query:)), keeps what loads, and fetches the next page as the row showing the last story appears, so the view using it holds no state for it:

```swift
import SwiftUI
import StoryblokClient
import StoryblokUI

struct ArticleList: View {
    let client: StoryblokClient<Content>

    var body: some View {
        List {
            Stories(client: client, query: StoriesQuery<Content.Article> { $0.startsWith = "articles/" }) { story in
                Text(story.content.headline)
            }
        }
    }
}
```

After the rows, `Stories` shows a loading view while there are more stories to come, and a message when the query matched none or a page failed to load. Each of these has a default you can replace.

`StoryblokUI` also makes a decoded ``/StoryblokClient/RichText`` value a `View` when its block library is one, rendering headings, lists, tables, images, code blocks and embedded blocks with native SwiftUI views:

```swift
struct ArticleBody: View {
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

Read <doc:UserGuide> to show paged stories, and <doc:RenderingRichText> to render rich text.

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
