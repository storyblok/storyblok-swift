//
//  JetNewsApp.swift
//  JetNews
//
//  Created by Nicholas Bransby-Williams on 30/04/2026.
//

import SwiftUI

import StoryblokClient
import StoryblokUI
internal import URLSessionExtension

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
                HomeView(client: client)
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
