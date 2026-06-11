# Rendering Storyblok rich text with RichTextView

How to render ``/StoryblokClient/RichText`` content as native SwiftUI views, customize individual node types, and handle internal story links.

## Getting Started

### Add package dependency

Add the *storyblok-swift* repository as a package to your `Package.swift` file and specify `RichTextView` as a dependency of the target in which you wish to use it:

```swift
dependencies: [
    …
    .package(url: "https://github.com/storyblok/storyblok-swift.git", .upToNextMajor(from: "0.1.0"))
]
targets: [
    .target(
        …
        dependencies: [
            .product(name: "RichTextView", package: "storyblok-swift")
        ]
    )
]
```

> Note: `RichTextView` builds on ``/StoryblokClient``. See the [StoryblokClient User Guide](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/userguide) for how to define a block library and fetch stories.

### Make your block library a `View`

`RichText` becomes a SwiftUI `View` only when its block library is itself a `View`. Conform your [`BlockLibrary`](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/blocklibrary) to `View` so that embedded component bloks render alongside the standard rich-text nodes:

```swift
import SwiftUI
import StoryblokClient

extension Content: View {
    var body: some View {
        switch self {
        case .article(let article): ArticleView(article: article)
        case .callout(let callout): CalloutView(callout: callout)
        case .unknown: EmptyView()
        }
    }
}
```

> Tip: Returning `EmptyView()` from the `unknown` case keeps unrecognised components from disrupting layout.

### Render rich text

With the conformance in place, import `RichTextView` and place a `RichText` value anywhere a `View` is expected:

```swift
import SwiftUI
import StoryblokClient
import RichTextView

struct ArticleBody: View {
    let content: RichText<Content>

    var body: some View {
        ScrollView {
            content
                .padding()
        }
    }
}
```

## Built-in rendering

Each node type renders with a default view designed to look reasonable out of the box:

| Node            | Default rendering                                                        |
|-----------------|--------------------------------------------------------------------------|
| Document        | A `LazyVStack` of its child nodes.                                        |
| Paragraph       | `Text` with inline marks; a lone image paragraph renders as the image.   |
| Heading         | `Text` sized by heading level (`largeTitle` … `subheadline`).            |
| Text            | An `AttributedString` carrying its inline marks.                         |
| Bullet / Ordered list | Indented rows with depth-aware bullets or numbers.                 |
| Blockquote      | A leading accent bar beside the quoted content.                          |
| Code block      | Monospaced `Text` on a rounded, tinted background.                       |
| Image           | `AsyncImage` with loading and failure placeholders.                      |
| Table           | A `Grid` with header and cell styling, honoring column spans.            |
| Embedded blok   | The component rendered through your block library's `View` conformance.  |
| Emoji           | The emoji character.                                                     |
| Horizontal rule | A `Divider`.                                                             |
| Hard break      | A line break.                                                            |

### Inline marks

Formatting marks on a text run — bold, italic, underline, strikethrough, inline code, subscript, superscript, links, and text/highlight colors — are accumulated and applied together into a single `AttributedString`. Color marks (`textStyle` and `highlight`) are parsed from CSS color values. Unknown marks are ignored.

## Customizing node rendering

To override how specific node types render, conform a type to ``RichTextViewDelegate`` and install it with ``RichTextView/SwiftUICore/View/richTextViewDelegate(_:)``. Every requirement has a default implementation matching the built-in renderer, so you implement only the node types you want to change:

```swift
struct MyDelegate: RichTextViewDelegate {
    typealias BlockLibrary = Content

    @MainActor
    func view(for heading: RichText<Content>.Heading) -> any View {
        Text(heading.attributedString())
            .font(.system(.title, design: .serif))
    }

    @MainActor
    func view(for codeBlock: RichText<Content>.CodeBlock) -> any View {
        MySyntaxHighlightedCode(codeBlock)
    }
}

ScrollView { article.content }
    .richTextViewDelegate(MyDelegate())
```

The delegate's `BlockLibrary` associated type must match the rich text being rendered. The delegate applies to all rich text in the view hierarchy below the modifier; node types it does not implement keep their defaults.

> Note: Inline marks and unknown nodes have no delegate hook. Marks are rendered as part of their containing text run, and ``RichTextViewDelegate/viewForHorizontalRule()`` takes no node value because a horizontal rule carries no data.

## Handling story links

Rich-text links that point at another Storyblok story are rendered with a `storyblok-story://<uuid>` URL rather than a web address. Use ``RichTextView/SwiftUICore/View/onStoryLink(_:)`` to intercept taps on those links and navigate within your app, while ordinary web and email links continue to open through the system:

```swift
ScrollView { article.content }
    .onStoryLink { uuid, anchor in
        router.navigate(to: uuid, anchor: anchor)
    }
```

The ``StoryLinkHandler`` receives the linked story's UUID and an optional anchor fragment. Links to external URLs and `mailto:` addresses are left to the standard [`openURL`](https://developer.apple.com/documentation/swiftui/environmentvalues/openurl) handling.

## See Also

- [StoryblokClient User Guide](https://storyblok.github.io/storyblok-swift/documentation/storyblokclient/userguide)
- [Storyblok rich text](https://www.storyblok.com/docs/richtext-field)
