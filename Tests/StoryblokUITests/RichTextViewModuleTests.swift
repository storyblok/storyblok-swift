import SwiftUI
import Testing
// Only the deprecated module, not StoryblokUI, so the names below must come through its re-export.
import RichTextView

@Suite
struct RichTextViewModuleTests {

    @Test @MainActor
    func `importing RichTextView still provides the rich text API`() {
        let handler: StoryLinkHandler = { _, _ in }
        let delegate: (any RichTextViewDelegate).Type? = nil

        _ = EmptyView().onStoryLink(handler)
        #expect(delegate == nil)
    }
}
