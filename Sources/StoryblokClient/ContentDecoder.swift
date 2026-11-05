import Foundation

/// A type whose blank Storyblok value, `""`, decodes as `nil` into an optional: a Date/Time field left blank, or a
/// Single-Option field sourced from stories with no story selected, modelled as a `UUID`.
private protocol BlankAsNil: Decodable {}

extension Date: BlankAsNil {}
extension UUID: BlankAsNil {}

/// An optional of a ``BlankAsNil`` type, so that `""` decodes as `nil` where the optional itself is asked for, such
/// as an element of `[Date?]` or a property whose type is a typealias of `Date?`.
private protocol BlankableOptional {
    static var blank: Self { get }
}

extension Optional: BlankableOptional where Wrapped: BlankAsNil {
    static var blank: Self { nil }
}

/// A number type that can be decoded from the text Storyblok sends for a Number field, such as `"42"` or `"4.5"`.
private protocol NumberText: Decodable {
    /// Reads `numberText`, which ``numberTextPattern`` has matched, or returns `nil` if it is not a value of this
    /// type, such as a fraction for an integer type or a number out of its range.
    init?(numberText: String)

    /// The name errors give the type, since `Decimal` describes itself as `NSDecimal`.
    static var numberName: String { get }
}

extension NumberText {
    static var numberName: String { "\(Self.self)" }

    /// Reads `text`, returning `nil` for a blank Number field's `""`, and throwing `corrupted` with a description if
    /// it is not a number of this type.
    static func read(_ text: String, corrupted: (String) -> DecodingError) throws -> Self? {
        if text.isEmpty { return nil }
        guard text.wholeMatch(of: numberTextPattern) != nil, let value = Self(numberText: text) else {
            throw corrupted("Cannot decode \(numberName) from \"\(text)\"")
        }
        return value
    }

    /// The description of the error a blank Number field throws for a property that isn't optional.
    static var blankDescription: String {
        "Cannot decode \(numberName) from an empty string. A blank Number field decodes as nil only into an optional property."
    }
}

/// The grammar of a JSON number, which number text must match before a type reads it: number types' own
/// initializers take more, such as `"+12"`, `"inf"` or hexadecimal, and `Decimal(string:)` reads whatever number the
/// text starts with.
nonisolated(unsafe) private let numberTextPattern = /-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?/

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

// A floating-point initializer reads a number out of range as infinity, which decoding a JSON number would reject.

extension Double: NumberText {
    init?(numberText: String) {
        guard let value = Double(numberText), value.isFinite else { return nil }
        self = value
    }
}

extension Float: NumberText {
    init?(numberText: String) {
        guard let value = Float(numberText), value.isFinite else { return nil }
        self = value
    }
}

extension Decimal: NumberText {
    init?(numberText: String) {
        guard let value = Decimal(string: numberText, locale: Locale(identifier: "en_US_POSIX")), value.isFinite else { return nil }
        self = value
    }

    static var numberName: String { "Decimal" }
}

/// Wraps the decoder a ``ContentResponse`` is decoded with, so that a blank Date/Time or Single-Option field, which
/// Storyblok sends as `""`, decodes as `nil` into a `Date?` or `UUID?`, however the optional is spelled or reached,
/// and a number type decodes from the text Storyblok sends for a Number field (`"42"`) as well as from a JSON number.
/// A blank Number field decodes as `nil` for an optional property.
///
/// Only responses ``StoryblokClient`` decodes go through it, so any other decoder reads `""` as Foundation does.
/// Everything else is passed to the wrapped decoder. `Date`, `Data` and `URL` are decoded by it directly, as it would
/// without this wrapper; any other type is decoded from a wrapper around the decoder for its value, so that blank
/// values and number text are read the same way at any depth, including in the stories a relation resolves to.
struct ContentDecoder: Decoder {

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

/// Whether the wrapped decoder must decode `type` itself: `Date` and `Data` to apply its decoding strategies, and
/// `URL`, which it reads from a string, where `URL`'s own `init(from:)` expects a keyed representation.
private func decodedByBase<T>(_ type: T.Type) -> Bool {
    type == Date.self || type == Data.self || type == URL.self
}

/// Decodes `type` from `container`, from a JSON number or from number text.
private func decodeNumber<N: NumberText>(_ type: N.Type, from container: any SingleValueDecodingContainer) throws -> N {
    guard let value = try decodeNumberOrBlank(type, from: container) else {
        throw DecodingError.dataCorruptedError(in: container, debugDescription: N.blankDescription)
    }
    return value
}

/// Like ``decodeNumber(_:from:)``, but a blank Number field's `""` decodes as `nil`.
///
/// The JSON number is tried first, so that it costs one decode. Anything that is neither a number nor text throws the
/// number's own type mismatch.
private func decodeNumberOrBlank<N: NumberText>(_ type: N.Type, from container: any SingleValueDecodingContainer) throws -> N? {
    do {
        return try container.decode(type)
    } catch let mismatch as DecodingError {
        guard case .typeMismatch = mismatch, let text = try? container.decode(String.self) else { throw mismatch }
        return try N.read(text) { DecodingError.dataCorruptedError(in: container, debugDescription: $0) }
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
        if let optional = type as? any BlankableOptional.Type, isBlank(forKey: key) {
            return optional.blank as! T
        }
        guard base.contains(key), !decodedByBase(type) else {
            return try base.decode(type, forKey: key)
        }
        return try T(from: ContentDecoder(base: base.superDecoder(forKey: key)))
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
        if type is any BlankAsNil.Type, isBlank(forKey: key) { return nil }
        return try decode(type, forKey: key)
    }

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        KeyedDecodingContainer(Keyed<NestedKey>(base: try base.nestedContainer(keyedBy: type, forKey: key)))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> any UnkeyedDecodingContainer {
        Unkeyed(base: try base.nestedUnkeyedContainer(forKey: key))
    }

    func superDecoder() throws -> any Decoder { ContentDecoder(base: try base.superDecoder()) }
    func superDecoder(forKey key: Key) throws -> any Decoder { ContentDecoder(base: try base.superDecoder(forKey: key)) }

    private func number<N: NumberText>(_ type: N.Type, forKey key: Key) throws -> N {
        guard let value = try numberOrBlank(type, forKey: key) else {
            throw DecodingError.dataCorruptedError(forKey: key, in: base, debugDescription: N.blankDescription)
        }
        return value
    }

    /// Like ``number(_:forKey:)``, but a missing key, `null` or a blank Number field's `""` decode as `nil`.
    private func numberIfPresent<N: NumberText>(_ type: N.Type, forKey key: Key) throws -> N? {
        guard base.contains(key), !(try base.decodeNil(forKey: key)) else { return nil }
        return try numberOrBlank(type, forKey: key)
    }

    /// Decodes a JSON number, or number text, returning `nil` for `""`. As ``decodeNumberOrBlank(_:from:)`` does,
    /// it tries the JSON number first and keeps the number's own type mismatch for a value that isn't text.
    private func numberOrBlank<N: NumberText>(_ type: N.Type, forKey key: Key) throws -> N? {
        do {
            return try base.decode(type, forKey: key)
        } catch let mismatch as DecodingError {
            guard case .typeMismatch = mismatch, let text = try? base.decode(String.self, forKey: key) else { throw mismatch }
            return try N.read(text) { DecodingError.dataCorruptedError(forKey: key, in: base, debugDescription: $0) }
        }
    }

    private func isBlank(forKey key: Key) -> Bool {
        (try? base.decode(String.self, forKey: key)) == ""
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
        if let optional = type as? any BlankableOptional.Type, skipBlank() {
            return optional.blank as! T
        }
        guard !isAtEnd, !decodedByBase(type) else { return try base.decode(type) }
        return try advancingOnSuccess { try T(from: ContentDecoder(base: $0.superDecoder())) }
    }

    mutating func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        KeyedDecodingContainer(Keyed<NestedKey>(base: try base.nestedContainer(keyedBy: type)))
    }

    mutating func nestedUnkeyedContainer() throws -> any UnkeyedDecodingContainer {
        Unkeyed(base: try base.nestedUnkeyedContainer())
    }

    mutating func superDecoder() throws -> any Decoder { ContentDecoder(base: try base.superDecoder()) }

    /// Decodes the next element through a decoder of its own.
    private mutating func number<N: NumberText>(_ type: N.Type) throws -> N {
        guard !isAtEnd else { return try base.decode(type) }
        return try advancingOnSuccess { try decodeNumber(type, from: $0.superDecoder().singleValueContainer()) }
    }

    /// Moves past the next element if it is `""`, returning whether it was.
    private mutating func skipBlank() -> Bool {
        (try? advancingOnSuccess { container -> Bool in
            guard try container.decode(String.self) == "" else { throw CancellationError() }
            return true
        }) ?? false
    }

    /// Runs `decode` on a copy of the wrapped container, keeping the copy only if it succeeds. `superDecoder()`
    /// moves past the element whether or not decoding it then succeeds, where the wrapped container's own `decode`
    /// stays on an element it fails to decode, so that a caller can try another type.
    private mutating func advancingOnSuccess<T>(_ decode: (inout any UnkeyedDecodingContainer) throws -> T) throws -> T {
        var attempt = base
        let value = try decode(&attempt)
        base = attempt
        return value
    }
}

// MARK: - Single value

private struct SingleValue: SingleValueDecodingContainer {

    let base: any SingleValueDecodingContainer
    /// The decoder this container decodes the value of, which decodes a type of its own from the same value.
    let decoder: ContentDecoder

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
        if let optional = type as? any BlankableOptional.Type, (try? base.decode(String.self)) == "" {
            return optional.blank as! T
        }
        guard !decodedByBase(type) else { return try base.decode(type) }
        return try T(from: decoder)
    }
}
