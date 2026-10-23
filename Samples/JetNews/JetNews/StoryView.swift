import SwiftUI
import Combine
import os

import StoryblokClient

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "JetNews", category: "main")

struct StoryView<Content: Decodable & View>: View {

    private let publisher: AnyPublisher<Story<Content>, Never>

    @State private var story: Story<Content>?

    init(
        _ publisher: AnyPublisher<Story<Content>, StoryblokClient<Block>.Error>,
        story: Story<Content>? = nil
    ) {
        self.publisher = publisher
            .receive(on: DispatchQueue.main)
            .catch { error in
                logger.error("Failed to load story: \(error)")
                return Just(story).compactMap { $0 }
            }
            .eraseToAnyPublisher()
        self._story = State(initialValue: story)
    }

    var body: some View {
        ScrollView {
            if let story {
                story.content
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .onReceive(publisher) { value in story = value }
        .refreshable {
            for await value in publisher.values {
                story = value
            }
        }
    }
}
