import Foundation
import StoryblokClient

/// The block library of the space the docs' Content Delivery API examples run against.
@BlockLibrary
enum Block {
    case author(Author)
    case category(Category)
    case page(body: [Block])
    case post(Post)
    case product(Product)

    struct Author {
        let name: String
    }

    struct Category {
        let name: String
    }

    struct Post {
        let title: String
        let author: String
        let topics: String
        let schedule: Date
        let categories: [String]
        let description: String
        let highlighted: Bool
    }

    struct Product {
        let name: String
        let price: String
        let featured: Bool
        let description: String
    }
}
