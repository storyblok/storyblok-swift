import SwiftUI
import StoryblokClient

struct ImageView<BL: View & Decodable>: View {
    let image: RichText<BL>.Image

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
            .accessibilityLabel(image.alt ?? image.title ?? "")
        }
    }
}
