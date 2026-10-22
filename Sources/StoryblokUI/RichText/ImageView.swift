import SwiftUI
import StoryblokClient

struct ImageView<BL: View & Decodable>: View {
    let image: RichText<BL>.Image

    /// The first non-empty description from `alt`, then `title`, ignoring surrounding whitespace.
    /// `nil` means the image carries no description and should be treated as decorative.
    var description: String? {
        [image.alt, image.title]
            .lazy
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }

    var body: some View {
        if let url = URL(string: image.src) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fit)
                case .failure:
                    Color.secondary.opacity(0.1)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(Color.secondary)
                        }
                case .empty:
                    Color.secondary.opacity(0.1)
                        .overlay(ProgressView())
                @unknown default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityLabel(Text(verbatim: description ?? ""))
            .accessibilityAddTraits(description == nil ? [] : .isImage)
            .accessibilityHidden(description == nil)
        }
    }
}
