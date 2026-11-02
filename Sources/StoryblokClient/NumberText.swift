import Foundation

/// A number type the client reads from the text Storyblok sends for a Number field, such as `"42"` or `"4.5"`.
private protocol NumberText: Decodable {
    /// Reads `numberText`, or returns `nil` if it is not a value of this type, such as `"4.5"` for an integer type.
    init?(numberText: String)
}

extension Int: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension Double: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension Float: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension Decimal: NumberText {
    fileprivate init?(numberText: String) { self.init(string: numberText, locale: Locale(identifier: "en_US_POSIX")) }
}

/// Decodes the number types from the text Storyblok sends for a Number field as well as from a JSON number, and a
/// blank optional Number field as `nil`.
///
/// As with the `Date?` overload, nothing calls these by name: the `Decodable` conformance Swift synthesizes, and the
/// decoding ``BlockLibrary()`` generates, call `decode(_:forKey:)` and `decodeIfPresent(_:forKey:)` for a number
/// property, and Swift picks these, declared in a module that imports the standard library's, over its own. Text is
/// read only by ``StoryblokClient``'s decoder: any other decoder decodes numbers as Foundation does.
extension KeyedDecodingContainer {

    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try number(type, forKey: key) }
    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try number(type, forKey: key) }
    public func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try number(type, forKey: key) }
    public func decode(_ type: Decimal.Type, forKey key: Key) throws -> Decimal { try number(type, forKey: key) }

    public func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Decimal.Type, forKey key: Key) throws -> Decimal? { try numberIfPresent(type, forKey: key) }

    private func number<N: NumberText>(_ type: N.Type, forKey key: Key) throws -> N {
        do {
            // Generic, so Foundation decodes the JSON number rather than the overloads above.
            return try decode(type, forKey: key)
        } catch DecodingError.typeMismatch where (try? superDecoder(forKey: key))?.userInfo[.storyblokContent] as? Bool == true {
            let text = try decode(String.self, forKey: key)
            guard let value = N(numberText: text) else {
                throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Cannot decode \(N.self) from \"\(text)\"")
            }
            return value
        }
    }

    private func numberIfPresent<N: NumberText>(_ type: N.Type, forKey key: Key) throws -> N? {
        guard contains(key), !(try decodeNil(forKey: key)) else { return nil }
        if try isBlankStoryblokValue(forKey: key) { return nil }
        return try number(type, forKey: key)
    }
}
