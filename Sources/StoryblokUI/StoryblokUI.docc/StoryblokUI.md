# ``StoryblokUI``

Show Storyblok stories in SwiftUI lists that load the next page as the user scrolls.

## Overview

``Stories`` produces rows for the stories matching a query, the way `ForEach` does, so you put it in a `List` or in a `LazyVStack` of your own. It fetches the stories a page at a time with ``/StoryblokClient``'s ``/StoryblokClient/StoryblokClient/stories(page:pageSize:resolveLevel:query:)``, keeps what loads, and fetches the next page as the row showing the last story appears, so the view using it holds no state for it:

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

Read <doc:UserGuide> to get started.

## Topics

### Essentials

- <doc:UserGuide>

### Showing stories

- ``Stories``
- ``Stories/init(client:pageSize:resolveLevel:query:row:loading:empty:failure:)``
