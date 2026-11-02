import Foundation

/// A number type the client reads from the text Storyblok sends for a Number field, such as `"42"` or `"4.5"`.
private protocol NumberText: Decodable {
    /// Reads `numberText`, or returns `nil` if it is not a value of this type, such as `"4.5"` for an integer type.
    init?(numberText: String)
}

extension Int: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension Int8: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension Int16: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension Int32: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension Int64: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension UInt: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension UInt8: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension UInt16: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension UInt32: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension UInt64: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }

// A floating-point initializer reads a number out of range as infinity, which decoding a JSON number would reject.

extension Double: NumberText {
    fileprivate init?(numberText: String) {
        guard let value = Double(numberText), value.isFinite else { return nil }
        self = value
    }
}

extension Float: NumberText {
    fileprivate init?(numberText: String) {
        guard let value = Float(numberText), value.isFinite else { return nil }
        self = value
    }
}

extension Decimal: NumberText {
    fileprivate init?(numberText: String) {
        // `Decimal(string:)` reads whatever number the text starts with, so the whole text must be a number first.
        guard Double(numberText)?.isFinite == true else { return nil }
        self.init(string: numberText, locale: Locale(identifier: "en_US_POSIX"))
    }
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
    public func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try number(type, forKey: key) }
    public func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try number(type, forKey: key) }
    public func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try number(type, forKey: key) }
    public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try number(type, forKey: key) }
    public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try number(type, forKey: key) }
    public func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try number(type, forKey: key) }
    public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try number(type, forKey: key) }
    public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try number(type, forKey: key) }
    public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try number(type, forKey: key) }
    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try number(type, forKey: key) }
    public func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try number(type, forKey: key) }
    public func decode(_ type: Decimal.Type, forKey key: Key) throws -> Decimal { try number(type, forKey: key) }

    public func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? { try numberIfPresent(type, forKey: key) }
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
