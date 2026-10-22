import SwiftUI
import StoryblokClient

// MARK: - List depth environment

private struct RichTextListDepthKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    var richTextListDepth: Int {
        get { self[RichTextListDepthKey.self] }
        set { self[RichTextListDepthKey.self] = newValue }
    }
}

private func bulletCharacter(depth: Int) -> String {
    ["•", "◦", "▪"][depth % 3]
}

// MARK: - Bullet list

struct BulletListView<BL: View & Decodable>: View {
    let list: RichText<BL>.BulletList
    @Environment(\.richTextListDepth) private var depth

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(list.content.indices, id: \.self) { i in
                if case .listItem(let item) = list.content[i] {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(verbatim: bulletCharacter(depth: depth))
                            .frame(minWidth: 16, alignment: .trailing)
                        ListItemContentView(item: item)
                    }
                }
            }
        }
        .environment(\.richTextListDepth, depth + 1)
    }
}

// MARK: - Ordered list

struct OrderedListView<BL: View & Decodable>: View {
    let list: RichText<BL>.OrderedList
    @Environment(\.richTextListDepth) private var depth

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(list.content.indices, id: \.self) { i in
                if case .listItem(let item) = list.content[i] {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(verbatim: "\((list.order ?? 1) + i).")
                            .monospacedDigit()
                            .frame(minWidth: 24, alignment: .trailing)
                        ListItemContentView(item: item)
                    }
                }
            }
        }
        .environment(\.richTextListDepth, depth + 1)
    }
}

// MARK: - List item content

struct ListItemContentView<BL: View & Decodable>: View {
    let item: RichText<BL>.ListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(item.content.indices, id: \.self) { i in
                item.content[i]
            }
        }
    }
}
