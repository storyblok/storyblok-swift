import SwiftUI
import StoryblokClient
import StoryblokUI

// MARK: - HomeView
// The home feed, made searchable. While search is active the feed is replaced by the matching posts,
// loaded a page at a time as the user scrolls.
struct HomeView: View {
    let client: StoryblokClient<Block>

    @State private var text = ""
    @State private var term = ""
    @State private var isSearchPresented = false

    var body: some View {
        Group {
            if isSearchPresented {
                searchResults
            } else {
                StoryView<Block>(client.story("home"))
            }
        }
        .searchable(text: $text, isPresented: $isSearchPresented, prompt: "Search posts")
        .task(id: text) {
            // Debounce typing, so a request goes out once the user pauses rather than per keystroke.
            do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
            term = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private var searchResults: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Loads the posts while search is open, the next page as the last row appears, and
                // starts again whenever the term changes. A blank term omits `search_term`, so the
                // endpoint returns all posts.
                Stories(client: client, query: StoriesQuery<Block.Post> { $0.searchTerm = term.isEmpty ? nil : term }) { story in
                    // Navigating keeps search active, so the results are still here when the user comes back.
                    PostCardSimple(story: story)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    Divider()
                        .padding(.leading, 72 + 16)
                } loading: {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, minHeight: 80)
                } empty: {
                    ContentUnavailableView.search(text: term)
                } failure: { _, retry in
                    ContentUnavailableView {
                        Label("Couldn't load posts", systemImage: "exclamationmark.triangle")
                    } actions: {
                        Button("Retry", action: retry)
                    }
                }
            }
        }
    }
}
