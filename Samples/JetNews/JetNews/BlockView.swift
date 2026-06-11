import Foundation
import StoryblokClient
import RichTextView
import SwiftUI

extension Block: View {
    var body: some View {
        switch self {

        // MARK: Content Types
                
        case .post(let post): post //Post comforms to View (below)
                
        case .page(let blocks):
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(blocks, id: \.self) { $0 }
            }
                
        // MARK: Nestables - Post
                
        case let .header(altTitle, altSubtitle, altImage):
            PostHeaderView(altTitle: altTitle, altSubtitle: altSubtitle, altImage: altImage)
                
        case .metadata:
            PostMetadataView()
                
        // MARK: Nestables - Feed
                
        case let .highlighted(title, post):
            VStack(alignment: .leading, spacing: 0) {
                Text(title.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                PostCardTop(story: post)
            }

        case let .popular(title, posts):
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.horizontal)
                    .padding(.top, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(posts, id: \.self) { story in
                            PostCardPopular(story: story)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }

        case let .recent(posts):
            VStack(alignment: .leading, spacing: 0) {
                ForEach(posts, id: \.self) { story in
                    PostCardSimple(story: story)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    Divider()
                        .padding(.leading, 72 + 16)
                }
            }
            .padding(.top, 8)

        case let .recommended(strapline, posts):
            VStack(alignment: .leading, spacing: 0) {
                Text(strapline.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                ForEach(posts, id: \.self) { story in
                    PostCardHistory(story: story)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    Divider()
                        .padding(.leading, 72 + 16)
                }
            }

        // MARK: Author blocks are never rendered standalone
        case .author:
            fatalError("No view for author")

        #if !DEBUG
        // MARK: Unknown components — silently ignored in release builds
        case .unknown:
            EmptyView()
        #endif
        }
    }
}

// MARK: - Environment key for selected post

struct PostKey: EnvironmentKey {
    static let defaultValue: Block.Post? = nil
}

extension EnvironmentValues {
    var post: Block.Post? {
        get { self[PostKey.self] }
        set { self[PostKey.self] = newValue }
    }
}

extension Block.Post: View, RichTextViewDelegate {
    typealias BlockLibrary = Block

    var body: some View {
        text.richTextViewDelegate(self)
            .environment(\.post, self)
            .padding(.horizontal)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let urlString = url.url,
                   let url = URL(string: urlString) {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ShareLink(item: url)
                    }
                }
            }
    }
    
    func view(for blockquote: RichText<Block>.Blockquote) -> any View {
        VStack(spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.title)
                .foregroundStyle(.secondary)
            ForEach(blockquote.content.indices, id: \.self) { i in
                blockquote.content[i]
                    .font(.title3.italic())
                    .multilineTextAlignment(.center)
            }
            Image(systemName: "quote.closing")
                .font(.title)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

}

// MARK: - PostHeaderView
// Rendered by the .header Block case — reads the surrounding post from environment
struct PostHeaderView: View {
    let altTitle: String
    let altSubtitle: String
    let altImage: Field.Asset
    
    @Environment(\.post) private var post

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let filename = altImage.filename.isEmpty ? (post?.image.filename ?? "") : altImage.filename
            if !filename.isEmpty {
                AsyncImage(url: URL(string: filename)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Rectangle().foregroundStyle(.quaternary)
                    default:
                        Rectangle().foregroundStyle(.quinary).overlay(ProgressView())
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .clipped()
            }

            VStack(alignment: .leading, spacing: 4) {
                let displayTitle = altTitle.isEmpty ? (post?.title ?? "") : altTitle
                if !displayTitle.isEmpty {
                    Text(displayTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                let displaySubtitle: String? = altSubtitle.isEmpty ? post?.subtitle : altSubtitle
                if let displaySubtitle {
                    Text(displaySubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top)
        }
    }
}

// MARK: - PostMetadataView
// Rendered by the .metadata Block case — reads the surrounding post from environment
struct PostMetadataView: View {
    @Environment(\.post) private var post

    var body: some View {
        if let post {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    if let author = post.author?.content {
                        Text(author.name)
                            .font(.callout)
                            .fontWeight(.medium)
                    }

                    let dateString = post.date.formatted(.dateTime.month(.abbreviated).day())
                    Text("\(dateString) · \(post.readTimeMinutes) min read")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Environment key for favorites binding

struct FavoritesKey: EnvironmentKey {
    static let defaultValue: Binding<Set<String>> = .constant([])
}

extension EnvironmentValues {
    var favorites: Binding<Set<String>> {
        get { self[FavoritesKey.self] }
        set { self[FavoritesKey.self] = newValue }
    }
}

// MARK: - Shared atoms

struct PostThumbnail: View {
    let asset: Field.Asset

    var body: some View {
        AsyncImage(url: URL(string: asset.filename)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Rectangle().foregroundStyle(.quaternary)
            default:
                Rectangle().foregroundStyle(.quinary).overlay(ProgressView())
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AuthorAndReadTime: View {
    let author: String?
    let readTime: String

    var body: some View {
        let parts = [author, "\(readTime) min read"].compactMap { $0 }
        Text(parts.joined(separator: " · "))
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

// MARK: - PostCardTop (highlighted / featured)

struct PostCardTop: View {
    let story: Story<Block.Post>

    private var post: Block.Post { story.content }

    var body: some View {
        NavigationLink(value: story) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: URL(string: post.image.filename)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Rectangle().foregroundStyle(.quaternary)
                    default:
                        Rectangle().foregroundStyle(.quinary).overlay(ProgressView())
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 200)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(3)
                        .foregroundStyle(.primary)

                    AuthorAndReadTime(
                        author: post.author?.content.name,
                        readTime: post.readTimeMinutes
                    )
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PostCardPopular (horizontal scroll card)

struct PostCardPopular: View {
    let story: Story<Block.Post>

    private var post: Block.Post { story.content }

    var body: some View {
        NavigationLink(value: story) {
            VStack(alignment: .leading, spacing: 0) {
                AsyncImage(url: URL(string: post.thumbnailImage.filename)) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        Rectangle().foregroundStyle(.quaternary)
                    default:
                        Rectangle().foregroundStyle(.quinary).overlay(ProgressView())
                    }
                }
                .frame(height: 110)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .foregroundStyle(.primary)

                    AuthorAndReadTime(
                        author: post.author?.content.name,
                        readTime: post.readTimeMinutes
                    )
                }
                .padding(10)
            }
            .frame(width: 260)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PostCardSimple (recent articles with bookmark)

struct PostCardSimple: View {
    let story: Story<Block.Post>
    @Environment(\.favorites) private var favorites

    private var post: Block.Post { story.content }
    private var storyId: String { story.uuid.uuidString }
    private var isBookmarked: Bool { favorites.wrappedValue.contains(storyId) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            NavigationLink(value: story) {
                HStack(alignment: .top, spacing: 12) {
                    PostThumbnail(asset: post.thumbnailImage)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.title)
                            .font(.headline)
                            .lineLimit(3)
                            .foregroundStyle(.primary)

                        AuthorAndReadTime(
                            author: post.author?.content.name,
                            readTime: post.readTimeMinutes
                        )
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                if isBookmarked {
                    favorites.wrappedValue.remove(storyId)
                } else {
                    favorites.wrappedValue.insert(storyId)
                }
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(isBookmarked ? .primary : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - PostCardHistory (recommended articles with context menu)

struct PostCardHistory: View {
    let story: Story<Block.Post>
    @State private var showFewerAlert = false

    private var post: Block.Post { story.content }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            NavigationLink(value: story) {
                HStack(alignment: .top, spacing: 12) {
                    PostThumbnail(asset: post.thumbnailImage)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.title)
                            .font(.headline)
                            .lineLimit(3)
                            .foregroundStyle(.primary)

                        AuthorAndReadTime(
                            author: post.author?.content.name,
                            readTime: post.readTimeMinutes
                        )
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Menu {
                Button("Show fewer stories like this", role: .destructive) {
                    showFewerAlert = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
        }
        .padding(.vertical, 4)
        .alert("Show fewer stories like this?", isPresented: $showFewerAlert) {
            Button("OK", role: .cancel) {}
        }
    }
}
