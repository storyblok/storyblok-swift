import SwiftUI

/// A callback invoked when an internal Storyblok story link is tapped.
public typealias StoryLinkHandler = @Sendable (UUID, _ anchor: String?) -> Void

private struct StoryLinkHandlerKey: EnvironmentKey {
    static let defaultValue: StoryLinkHandler? = nil
}

extension EnvironmentValues {
    var storyLinkHandler: StoryLinkHandler? {
        get { self[StoryLinkHandlerKey.self] }
        set { self[StoryLinkHandlerKey.self] = newValue }
    }
}

extension View {
    /// Registers a callback invoked when a Storyblok story link is tapped within this view.
    public func onStoryLink(_ handler: @escaping StoryLinkHandler) -> some View {
        environment(\.storyLinkHandler, handler)
            .environment(\.openURL, OpenURLAction { url in
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
