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

/// Wraps the decoder a ``ContentResponse`` is decoded with, so that a blank Date/Time or Single-Option field, which
/// Storyblok sends as `""`, decodes as `nil` into a `Date?` or `UUID?`, however the optional is spelled or reached.
///
/// Only responses ``StoryblokClient`` decodes go through it, so any other decoder reads `""` as Foundation does.
/// Everything else is passed to the wrapped decoder. `Date`, `Data` and `URL` are decoded by it directly, as it would
/// without this wrapper; any other type is decoded from a wrapper around the decoder for its value, so that blank
/// values are read the same way at any depth, including in the stories a relation resolves to.
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

// MARK: - Keyed

private struct Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {

    let base: KeyedDecodingContainer<Key>

    var codingPath: [any CodingKey] { base.codingPath }
    var allKeys: [Key] { base.allKeys }

    func contains(_ key: Key) -> Bool { base.contains(key) }
    func decodeNil(forKey key: Key) throws -> Bool { try base.decodeNil(forKey: key) }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool { try base.decode(type, forKey: key) }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { try base.decode(type, forKey: key) }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { try base.decode(type, forKey: key) }
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float { try base.decode(type, forKey: key) }
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int { try base.decode(type, forKey: key) }
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 { try base.decode(type, forKey: key) }
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 { try base.decode(type, forKey: key) }
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 { try base.decode(type, forKey: key) }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 { try base.decode(type, forKey: key) }
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt { try base.decode(type, forKey: key) }
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 { try base.decode(type, forKey: key) }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { try base.decode(type, forKey: key) }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { try base.decode(type, forKey: key) }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { try base.decode(type, forKey: key) }

    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        if let optional = type as? any BlankableOptional.Type, isBlank(forKey: key) {
            return optional.blank as! T
        }
        guard base.contains(key), !decodedByBase(type) else {
            return try base.decode(type, forKey: key)
        }
        return try T(from: ContentDecoder(base: base.superDecoder(forKey: key)))
    }

    func decodeIfPresent<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T? {
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
    mutating func decode(_ type: Double.Type) throws -> Double { try base.decode(type) }
    mutating func decode(_ type: Float.Type) throws -> Float { try base.decode(type) }
    mutating func decode(_ type: Int.Type) throws -> Int { try base.decode(type) }
    mutating func decode(_ type: Int8.Type) throws -> Int8 { try base.decode(type) }
    mutating func decode(_ type: Int16.Type) throws -> Int16 { try base.decode(type) }
    mutating func decode(_ type: Int32.Type) throws -> Int32 { try base.decode(type) }
    mutating func decode(_ type: Int64.Type) throws -> Int64 { try base.decode(type) }
    mutating func decode(_ type: UInt.Type) throws -> UInt { try base.decode(type) }
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 { try base.decode(type) }
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 { try base.decode(type) }
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 { try base.decode(type) }
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 { try base.decode(type) }

    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
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
    func decode(_ type: Double.Type) throws -> Double { try base.decode(type) }
    func decode(_ type: Float.Type) throws -> Float { try base.decode(type) }
    func decode(_ type: Int.Type) throws -> Int { try base.decode(type) }
    func decode(_ type: Int8.Type) throws -> Int8 { try base.decode(type) }
    func decode(_ type: Int16.Type) throws -> Int16 { try base.decode(type) }
    func decode(_ type: Int32.Type) throws -> Int32 { try base.decode(type) }
    func decode(_ type: Int64.Type) throws -> Int64 { try base.decode(type) }
    func decode(_ type: UInt.Type) throws -> UInt { try base.decode(type) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { try base.decode(type) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { try base.decode(type) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { try base.decode(type) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { try base.decode(type) }

    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        if let optional = type as? any BlankableOptional.Type, (try? base.decode(String.self)) == "" {
            return optional.blank as! T
        }
        guard !decodedByBase(type) else { return try base.decode(type) }
        return try T(from: decoder)
    }
}
