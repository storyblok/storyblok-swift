import Foundation

/// A number type the client reads from the text Storyblok sends for a Number field, such as `"42"` or `"4.5"`.
private protocol NumberText: Decodable {
    /// Reads `numberText`, plain decimal text such as `"-4.5"`, or returns `nil` if it is not a value of this type,
    /// such as `"4.5"` for an integer type, or one too large for it.
    init?(numberText: String)

    /// The name errors give the type, since `Decimal` describes itself as `NSDecimal`.
    static var numberName: String { get }
}

extension NumberText {
    fileprivate static var numberName: String { "\(Self.self)" }
}

extension Int: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
extension Int64: NumberText { fileprivate init?(numberText: String) { self.init(numberText) } }
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
    fileprivate init?(numberText: String) { self.init(string: numberText, locale: Locale(identifier: "en_US_POSIX")) }
    fileprivate static var numberName: String { "Decimal" }
}

/// Decodes the number types from the text Storyblok sends for a Number field as well as from a JSON number, and a
/// blank optional Number field as `nil`.
///
/// As with the `Date?` overload, nothing calls these by name: the `Decodable` conformance Swift synthesizes, and the
/// decoding ``BlockLibrary()`` generates, call `decode(_:forKey:)` and `decodeIfPresent(_:forKey:)` for a number
/// property, and Swift picks these over the standard library's. For `Int`, `Int64`, `Double` and `Float`, it does so
/// only in a file that imports StoryblokClient: the standard library declares the same overloads, and wins elsewhere.
/// Text is read only by ``StoryblokClient``'s decoder: any other decoder decodes numbers as Foundation does.
extension KeyedDecodingContainer {

    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try number(type, forKey: key) }
    public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try number(type, forKey: key) }
    public func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try number(type, forKey: key) }
    public func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try number(type, forKey: key) }
    public func decode(_ type: Decimal.Type, forKey key: Key) throws -> Decimal { try number(type, forKey: key) }

    public func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? { try numberIfPresent(type, forKey: key) }
    public func decodeIfPresent(_ type: Decimal.Type, forKey key: Key) throws -> Decimal? { try numberIfPresent(type, forKey: key) }

    private func number<N: NumberText>(_ type: N.Type, forKey key: Key) throws -> N {
        guard let value = try numberOrBlank(type, forKey: key) else {
            throw DecodingError.dataCorruptedError(
                forKey: key, in: self,
                debugDescription: "Cannot decode \(N.numberName) from an empty string. A blank Number field decodes as nil only into an optional property."
            )
        }
        return value
    }

    private func numberIfPresent<N: NumberText>(_ type: N.Type, forKey key: Key) throws -> N? {
        guard contains(key), !(try decodeNil(forKey: key)) else { return nil }
        return try numberOrBlank(type, forKey: key)
    }

    /// Decodes a JSON number or, from ``StoryblokClient``'s decoder, number text, returning `nil` for `""`.
    ///
    /// The JSON number is tried first, so that the common case costs no more than Foundation's decoding. Only a string
    /// is probed for the client's mark, so a decoder whose `superDecoder(forKey:)` traps traps only for one.
    private func numberOrBlank<N: NumberText>(_ type: N.Type, forKey key: Key) throws -> N? {
        do {
            // Generic, so Foundation decodes the JSON number rather than the overloads above.
            return try decode(type, forKey: key)
        } catch let mismatch as DecodingError {
            guard case .typeMismatch = mismatch,
                  let text = try? decode(String.self, forKey: key),
                  (try? superDecoder(forKey: key))?.userInfo[.storyblokContent] as? Bool == true
            else { throw mismatch }
            if text.isEmpty { return nil }
            guard text.wholeMatch(of: /-?[0-9]+(\.[0-9]+)?/) != nil, let value = N(numberText: text) else {
                throw DecodingError.dataCorruptedError(
                    forKey: key, in: self, debugDescription: "Cannot decode \(N.numberName) from \"\(text)\""
                )
            }
            return value
        }
    }
}
