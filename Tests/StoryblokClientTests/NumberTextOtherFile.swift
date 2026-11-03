import Foundation

/// A model declared in a file that imports Foundation but not StoryblokClient, where the standard library's `Int`
/// overload wins over the client's.
struct ForeignProduct: Decodable {
    let stock: Int
    let tax: Decimal
}
