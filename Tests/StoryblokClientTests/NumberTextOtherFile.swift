import Foundation

/// A model declared in a file that imports Foundation but not StoryblokClient, which must read number text all the
/// same.
struct ForeignProduct: Decodable {
    let stock: Int
    let tax: Decimal
}
