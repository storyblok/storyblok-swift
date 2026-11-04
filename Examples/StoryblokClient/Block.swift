import Foundation
import StoryblokClient

/// The block library of the space the docs' Content Delivery API examples run against.
///
/// The content types' fields are optional, as the Kotlin examples' fixtures are, since a story can leave a field unset.
@BlockLibrary
enum Block {
    case author(Author)
    case category(Category)
    case feature(name: String)
    case featuredPosts(posts: [UUID])
    case grid(columns: [Block])
    case page(body: [Block])
    case post(Post)
    case product(Product)
    case teaser(headline: String)

    enum CodingKeys: String, CodingKey {
        case featuredPosts = "featured_posts"
    }

    struct Author {
        let name: String?
    }

    struct Category {
        let name: String?
    }

    struct Post {
        let title: String?
        let author: String?
        let topics: String?
        let schedule: Date?
        let categories: [String]?
        let description: String?
        let highlighted: Bool?
    }

    struct Product {
        let name: String?
        let price: String?
        let featured: Bool?
        let description: String?
    }
}
