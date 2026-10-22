import SwiftUI

/// A callback invoked when an internal Storyblok story link is tapped.
///
/// - Parameters:
///   - uuid: The UUID of the linked story.
///   - anchor: The optional anchor fragment within the target story, if the link specified one.
public typealias StoryLinkHandler = @Sendable (UUID, _ anchor: String?) -> Void

extension View {
    /// Registers a callback invoked when an internal Storyblok story link is tapped within this
    /// view hierarchy.
    ///
    /// Rich-text links pointing at another story (`linktype` `"story"`) are rendered with a
    /// `storyblok-story://<uuid>` URL. This modifier intercepts those URLs and routes them to
    /// your `handler` instead of opening them, while leaving ordinary web and email links to the
    /// system's default handling. Use it to navigate to the linked story in your app:
    ///
    /// ```swift
    /// ScrollView { article.content }
    ///     .onStoryLink { uuid, anchor in
    ///         navigate(to: uuid, anchor: anchor)
    ///     }
    /// ```
    ///
    /// - Parameter handler: The callback invoked with the linked story's UUID and optional anchor.
    public func onStoryLink(_ handler: @escaping StoryLinkHandler) -> some View {
        environment(\.openURL, OpenURLAction { url in
                guard
                    url.scheme == "storyblok-story",
                    let host = url.host,
                    let uuid = UUID(uuidString: host)
                else { return .systemAction }
                let anchor = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "anchor" })?.value
                handler(uuid, anchor)
                return .handled
            })
    }
}
