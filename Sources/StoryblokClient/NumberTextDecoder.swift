import Foundation

/// A number type that can be decoded from the text Storyblok sends for a Number field, such as `"42"` or `"4.5"`.
private protocol NumberText: Decodable {
    init?(numberText: String)
}

/// The text of a JSON number, so that `Decimal(string:)`, which reads whatever number the text starts with, and
/// `Double`, which also reads `"inf"` and hexadecimal, take nothing a Number field would not send.
nonisolated(unsafe) private let numberTextPattern = /-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?/

extension Int: NumberText { init?(numberText: String) { self.init(numberText) } }
extension Int8: NumberText { init?(numberText: String) { self.init(numberText) } }
extension Int16: NumberText { init?(numberText: String) { self.init(numberText) } }
extension Int32: NumberText { init?(numberText: String) { self.init(numberText) } }
extension Int64: NumberText { init?(numberText: String) { self.init(numberText) } }
extension UInt: NumberText { init?(numberText: String) { self.init(numberText) } }
extension UInt8: NumberText { init?(numberText: String) { self.init(numberText) } }
extension UInt16: NumberText { init?(numberText: String) { self.init(numberText) } }
extension UInt32: NumberText { init?(numberText: String) { self.init(numberText) } }
extension UInt64: NumberText { init?(numberText: String) { self.init(numberText) } }

extension Double: NumberText {
    init?(numberText: String) {
        guard numberText.wholeMatch(of: numberTextPattern) != nil else { return nil }
        self.init(numberText)
    }
}

extension Float: NumberText {
    init?(numberText: String) {
        guard numberText.wholeMatch(of: numberTextPattern) != nil else { return nil }
        self.init(numberText)
    }
}

extension Decimal: NumberText {
    init?(numberText: String) {
        guard numberText.wholeMatch(of: numberTextPattern) != nil else { return nil }
        self.init(string: numberText, locale: Locale(identifier: "en_US_POSIX"))
    }
}

/// Wraps the decoder a ``ContentResponse`` is decoded with, so that a number type decodes from the text Storyblok
/// sends for a Number field (`"42"`) as well as from a JSON number. A blank Number field, sent as `""`, decodes as
/// `nil` for an optional property.
///
/// Everything else is passed to the wrapped decoder. `Date` and `Data` are decoded by it directly, under its decoding
/// strategies; any other type is decoded from a wrapper around the decoder for its value, so that number text is read
/// the same way at any depth, including in the stories a relation resolves to.
struct NumberTextDecoder: Decoder {

    let base: any Decoder

    var codingPath: [any CodingKey] { base.codingPath }
    var userInfo: [CodingUserInfoKey: Any] { base.userInfo }

    func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        KeyedDecodingContainer(Keyed(base: try base.container(keyedBy: type)))
    }

    func unkeyedContainer() throws -> any UnkeyedDecodingContainer {
        Unkeyed(base: try base.unkeyedContainer())
    }

    func singleValueContainer() throws -> any SingleValueDecodingContainer {
        SingleValue(base: try base.singleValueContainer(), decoder: self)
    }
}

/// Whether the wrapped decoder must decode `type` itself, to apply its decoding strategy.
private func decodedByBase<T>(_ type: T.Type) -> Bool {
    type == Date.self || type == Data.self
}

/// Decodes `type` from `container`, from a JSON number or from number text.
private func decodeNumber<N: NumberText>(_ type: N.Type, from container: any SingleValueDecodingContainer) throws -> N {
    do {
        return try container.decode(type)
    } catch DecodingError.typeMismatch(_, _) where (try? container.decode(String.self)) != nil {
        let text = try container.decode(String.self)
        guard let value = N(numberText: text) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode \(N.self) from \"\(text)\"")
        }
        return value
    }
}

// MARK: - Keyed

private struct Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {

    let base: KeyedDecodingContainer<Key>

    var codingPath: [any CodingKey] { base.codingPath }
    var allKeys: [Key] { base.allKeys }

    func contains(_ key: Key) -> Bool { base.contains(key) }
    func decodeNil(forKey key: Key) throws -> Bool { try base.decodeNil(forKey: key) }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try base.decode(type, forKey: key) }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { try base.decode(type, forKey: key) }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try number(type, forKey: key) }
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try number(type, forKey: key) }
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try number(type, forKey: key) }
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try number(type, forKey: key) }
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try number(type, forKey: key) }
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try number(type, forKey: key) }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try number(type, forKey: key) }
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try number(type, forKey: key) }
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try number(type, forKey: key) }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try number(type, forKey: key) }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try number(type, forKey: key) }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try number(type, forKey: key) }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        if let type = type as? any NumberText.Type {
            return try number(type, forKey: key) as! T
        }
        guard base.contains(key), !decodedByBase(type) else {
            return try base.decode(type, forKey: key)
        }
        return try T(from: NumberTextDecoder(base: base.superDecoder(forKey: key)))
    }

    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? { try numberIfPresent(type, forKey: key) }
    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? { try numberIfPresent(type, forKey: key) }

    func decodeIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
        if let type = type as? any NumberText.Type {
            return try numberIfPresent(type, forKey: key) as! T?
        }
        guard base.contains(key), !(try base.decodeNil(forKey: key)) else { return nil }
        return try decode(type, forKey: key)
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        KeyedDecodingContainer(Keyed<NestedKey>(base: try base.nestedContainer(keyedBy: type, forKey: key)))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
        Unkeyed(base: try base.nestedUnkeyedContainer(forKey: key))
    }

    func superDecoder() throws -> any Decoder { NumberTextDecoder(base: try base.superDecoder()) }
    func superDecoder(forKey key: Key) throws -> any Decoder { NumberTextDecoder(base: try base.superDecoder(forKey: key)) }

    private func number<N: NumberText>(_ type: N.Type, forKey key: Key) throws -> N {
        guard base.contains(key) else { return try base.decode(type, forKey: key) }
        return try decodeNumber(type, from: base.superDecoder(forKey: key).singleValueContainer())
    }

    /// Like ``number(_:forKey:)``, but a missing key, `null` or a blank Number field's `""` decode as `nil`.
    private func numberIfPresent<N: NumberText>(_ type: N.Type, forKey key: Key) throws -> N? {
        guard base.contains(key), !(try base.decodeNil(forKey: key)) else { return nil }
        if (try? base.decode(String.self, forKey: key)) == "" { return nil }
        return try number(type, forKey: key)
    }
}

// MARK: - Unkeyed

private struct Unkeyed: UnkeyedDecodingContainer {

    var base: any UnkeyedDecodingContainer

    var codingPath: [any CodingKey] { base.codingPath }
    var count: Int? { base.count }
    var isAtEnd: Bool { base.isAtEnd }
    var currentIndex: Int { base.currentIndex }

    mutating func decodeNil() throws -> Bool { try base.decodeNil() }

    mutating func decode(_ type: Bool.Type) throws -> Bool { try base.decode(type) }
    mutating func decode(_ type: String.Type) throws -> String { try base.decode(type) }
    mutating func decode(_ type: Double.Type) throws -> Double { try number(type) }
    mutating func decode(_ type: Float.Type) throws -> Float { try number(type) }
    mutating func decode(_ type: Int.Type) throws -> Int { try number(type) }
    mutating func decode(_ type: Int8.Type) throws -> Int8 { try number(type) }
    mutating func decode(_ type: Int16.Type) throws -> Int16 { try number(type) }
    mutating func decode(_ type: Int32.Type) throws -> Int32 { try number(type) }
    mutating func decode(_ type: Int64.Type) throws -> Int64 { try number(type) }
    mutating func decode(_ type: UInt.Type) throws -> UInt { try number(type) }
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 { try number(type) }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { try number(type) }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { try number(type) }
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { try number(type) }

    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        if let type = type as? any NumberText.Type {
            return try number(type) as! T
        }
        guard !isAtEnd, !decodedByBase(type) else { return try base.decode(type) }
        return try T(from: NumberTextDecoder(base: base.superDecoder()))
    }

    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        KeyedDecodingContainer(Keyed<NestedKey>(base: try base.nestedContainer(keyedBy: type)))
    }

    mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
        Unkeyed(base: try base.nestedUnkeyedContainer())
    }

    mutating func superDecoder() throws -> any Decoder { NumberTextDecoder(base: try base.superDecoder()) }

    /// Decodes the next element through a decoder of its own, so that a failed attempt does not leave the index
    /// somewhere the next one does not expect.
    private mutating func number<N: NumberText>(_ type: N.Type) throws -> N {
        guard !isAtEnd else { return try base.decode(type) }
        return try decodeNumber(type, from: base.superDecoder().singleValueContainer())
    }
}

// MARK: - Single value

private struct SingleValue: SingleValueDecodingContainer {

    let base: any SingleValueDecodingContainer
    /// The decoder this container decodes the value of, which decodes a type of its own from the same value.
    let decoder: NumberTextDecoder

    var codingPath: [any CodingKey] { base.codingPath }

    func decodeNil() -> Bool { base.decodeNil() }

    func decode(_ type: Bool.Type) throws -> Bool { try base.decode(type) }
    func decode(_ type: String.Type) throws -> String { try base.decode(type) }
    func decode(_ type: Double.Type) throws -> Double { try decodeNumber(type, from: base) }
    func decode(_ type: Float.Type) throws -> Float { try decodeNumber(type, from: base) }
    func decode(_ type: Int.Type) throws -> Int { try decodeNumber(type, from: base) }
    func decode(_ type: Int8.Type) throws -> Int8 { try decodeNumber(type, from: base) }
    func decode(_ type: Int16.Type) throws -> Int16 { try decodeNumber(type, from: base) }
    func decode(_ type: Int32.Type) throws -> Int32 { try decodeNumber(type, from: base) }
    func decode(_ type: Int64.Type) throws -> Int64 { try decodeNumber(type, from: base) }
    func decode(_ type: UInt.Type) throws -> UInt { try decodeNumber(type, from: base) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { try decodeNumber(type, from: base) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try decodeNumber(type, from: base) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try decodeNumber(type, from: base) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { try decodeNumber(type, from: base) }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        if let type = type as? any NumberText.Type {
            return try decodeNumber(type, from: base) as! T
        }
        guard !decodedByBase(type) else { return try base.decode(type) }
        return try T(from: decoder)
    }
}
