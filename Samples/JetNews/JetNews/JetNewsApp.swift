//
//  JetNewsApp.swift
//  JetNews
//
//  Created by Nicholas Bransby-Williams on 30/04/2026.
//

import SwiftUI
import Combine
import os

import StoryblokClient
import RichTextView
internal import URLSessionExtension

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "main")

@main
struct JetNewsApp: App {
    @State private var path = NavigationPath()
    @State private var favorites: Set<String> = []

    private let client = StoryblokClient(library: Block.self, accessToken: "t56rE6UQJVErhMrkKvAe8Att", version: {
        #if DEBUG
        .draft
        #else
        .published
        #endif
    }())

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $path) {
                StoryView<Block>(client.story("home"))
                    .navigationTitle("JetNews")
                    .navigationBarTitleDisplayMode(.large)
                    .navigationDestination(for: String.self) { slug in
                        StoryView<Block>(client.story(slug))
                    }
                    .navigationDestination(for: UUID.self) { uuid in
                        StoryView<Block>(client.story(uuid))
                    }
                    .navigationDestination(for: Story<Block>.self) { story in
                        StoryView(client.story(story.uuid), story: story)
                    }
                    .navigationDestination(for: Story<Block.Post>.self) { story in
                        StoryView(client.story(story.uuid), story: story)
                    }

            }
            .onStoryLink { uuid, _ in path.append(uuid) }
            .environment(\.favorites, $favorites)
        }
    }
}
    
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

