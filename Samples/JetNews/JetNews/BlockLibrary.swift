import Foundation
import StoryblokClient
import SwiftUI

@BlockLibrary
enum Block : Decodable, Hashable {
    
    // MARK: - Post
    
    case post(Post)
    case author(Author)
    case header(altTitle: String, altSubtitle: String, altImage: Field.Asset)
    case metadata
    
    nonisolated struct Post : Decodable, Hashable {
        let title: String
        let subtitle: String?
        let url: Field.Link
        let image: Field.Asset
        let thumbnailImage: Field.Asset
        let text: RichText<Block>
        let date: Date
        let author: Story<Author>?
        let readTimeMinutes: String

        enum CodingKeys: String, CodingKey {
            case title, subtitle, url, image, thumbnailImage
            case text = "body"
            case date, author, readTimeMinutes
        }
    }
    
    nonisolated struct Author : Decodable, Hashable {
        let name: String
        let url: Field.Link?
    }
    
    enum HeaderCodingKeys: String, CodingKey {
        case altTitle = "alternativeTitle"
        case altSubtitle = "alternativeSubtitle"
        case altImage = "alternativeImage"
    }
    
    // MARK: - Feed

    case page(blocks: [Block])
    case highlighted(title: String, post: Story<Post>)
    case recent(posts: [Story<Post>])
    case popular(title: String, posts: [Story<Post>])
    case recommended(strapline: String, posts: [Story<Post>])
    
    enum PageCodingKeys: String, CodingKey {
        case blocks = "body"
    }
    
    // MARK: - Catch-all for component types not known to this client
    /// Only present in release builds — in debug the macro throws on
    /// unrecognised component names so problems surface immediately.
    #if !DEBUG
    case unknown
    #endif

}
