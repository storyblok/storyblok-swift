import Foundation

/// One [filter query](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries)
/// condition, as the `filter_query[<field>][<operation>]=<value>` parameter it becomes.
///
/// Build these with the operators and methods on the fields a ``StoriesQuery/filter(_:)`` block
/// is given rather than constructing them directly — `$0.price > 100`,
/// `$0.headline.like("*space*")`, `$0.categories.isNotEmpty`.
public struct Filter<Content : QueryableContent> : Sendable {

    let name: String
    let operation: String
    let value: String

    init(_ keyPath: AnyKeyPath, _ operation: String, _ value: String) {
        self.name = Content.fieldName(for: keyPath)
        self.operation = operation
        self.value = value
    }
}

/// Collects the conditions written in a ``StoriesQuery/filter(_:)`` block.
@resultBuilder
public enum FilterBuilder<Content : QueryableContent> {
    public static func buildBlock(_ filters: Filter<Content>...) -> [Filter<Content>] { filters }
    public static func buildArray(_ filters: [[Filter<Content>]]) -> [Filter<Content>] { filters.flatMap { $0 } }
    public static func buildOptional(_ filters: [Filter<Content>]?) -> [Filter<Content>] { filters ?? [] }
    public static func buildEither(first filters: [Filter<Content>]) -> [Filter<Content>] { filters }
    public static func buildEither(second filters: [Filter<Content>]) -> [Filter<Content>] { filters }
    public static func buildExpression(_ filter: Filter<Content>) -> [Filter<Content>] { [filter] }
    public static func buildExpression(_ filters: [Filter<Content>]) -> [Filter<Content>] { filters }
    public static func buildBlock(_ filters: [Filter<Content>]...) -> [Filter<Content>] { filters.flatMap { $0 } }
}

// MARK: - Addressing fields

/// The fields of `Content`, as the ``StoriesQuery/filter(_:)`` block sees them.
///
/// Members resolve through a key path, so `$0.price` is checked by the compiler exactly as
/// `\Content.price` would be — a misspelling does not compile — while reading like a property
/// access. Writing the key path inline instead (`\.price.asWholeNumber`) cannot be inferred by
/// Swift, since the member has to be resolved before the key path's root is known.
@dynamicMemberLookup
public struct Fields<Content : QueryableContent> : Sendable {

    public subscript<Value>(dynamicMember keyPath: KeyPath<Content, Value>) -> QueryField<Content, Value> {
        QueryField(keyPath)
    }
}

/// One field of `Content`, addressed for a filter condition.
///
/// `Value` is the field's own Swift type, which is what lets the operations below be offered only
/// where they mean something: an array operation exists on an array field and nowhere else.
public struct QueryField<Content : QueryableContent, Value> {

    let keyPath: AnyKeyPath

    init(_ keyPath: AnyKeyPath) { self.keyPath = keyPath }

    func filter(_ operation: String, _ value: String) -> Filter<Content> {
        Filter(keyPath, operation, value)
    }
}

// MARK: - Text

extension QueryField where Value == String {

    /// [like](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-like): the value matches `pattern`, which may contain `*` wildcards.
    public func like(_ pattern: String) -> Filter<Content> { filter("like", pattern) }

    /// [not_like](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-not-like): the value does not match `pattern`.
    public func notLike(_ pattern: String) -> Filter<Content> { filter("not_like", pattern) }

    /// [in](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-in): the value is one of `values`.
    public func `in`(_ values: [String]) -> Filter<Content> { filter("in", values.joined(separator: ",")) }

    /// [not_in](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-not-in): the value is none of `values`.
    public func notIn(_ values: [String]) -> Filter<Content> { filter("not_in", values.joined(separator: ",")) }

    /// Compare this text field as a whole number, mapping to `gt_int`/`lt_int`.
    ///
    /// Storyblok serialises a number field's value as a JSON string, so a numeric field is as
    /// likely to be modelled as a `String` as an `Int`. Saying so is deliberate rather than
    /// implicit: `$0.price.asWholeNumber > 100` reads as the decision it is.
    public var asWholeNumber: QueryField<Content, WholeNumberText> { QueryField<Content, WholeNumberText>(keyPath) }

    /// Compare this text field as a decimal, mapping to `gt_float`/`lt_float`.
    public var asDecimal: QueryField<Content, DecimalText> { QueryField<Content, DecimalText>(keyPath) }
}

extension QueryField where Value == String? {
    public func like(_ pattern: String) -> Filter<Content> { filter("like", pattern) }
    public func notLike(_ pattern: String) -> Filter<Content> { filter("not_like", pattern) }
    public func `in`(_ values: [String]) -> Filter<Content> { filter("in", values.joined(separator: ",")) }
    public func notIn(_ values: [String]) -> Filter<Content> { filter("not_in", values.joined(separator: ",")) }
    public var asWholeNumber: QueryField<Content, WholeNumberText> { QueryField<Content, WholeNumberText>(keyPath) }
    public var asDecimal: QueryField<Content, DecimalText> { QueryField<Content, DecimalText>(keyPath) }
}

/// Marker for a text field being compared as a whole number. Never instantiated.
public enum WholeNumberText {}
/// Marker for a text field being compared as a decimal. Never instantiated.
public enum DecimalText {}

// MARK: - Presence

/// The value types the [is](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-is)
/// operation matches on a single-value field.
///
/// Storyblok documents eight and does not declare the set closed; one added later is reachable by
/// writing the parameter out with ``StoriesQuery/parameter(_:_:)``. The two array cases are an
/// array field's `isEmpty` and `isNotEmpty`, offered only on array fields since the API matches
/// nothing when they are applied to a single-value one.
public enum Presence : String, Sendable {
    case empty
    case notEmpty = "not_empty"
    case isTrue = "true"
    case isFalse = "false"
    case null
    case notNull = "not_null"
}

extension QueryField {
    /// [is](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-is): the field holds the given kind of value.
    public func `is`(_ presence: Presence) -> Filter<Content> { filter("is", presence.rawValue) }
}

// MARK: - Arrays

extension QueryField where Value == [String] {

    /// [all_in_array](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-all-in-array): the field contains every one of `values`.
    public func contains(allOf values: [String]) -> Filter<Content> {
        filter("all_in_array", values.joined(separator: ","))
    }

    /// [any_in_array](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-any-in-array): the field contains any of `values`.
    public func contains(anyOf values: [String]) -> Filter<Content> {
        filter("any_in_array", values.joined(separator: ","))
    }

    /// [is](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-is)
    /// `empty_array`: the field holds no entries.
    public var isEmpty: Filter<Content> { filter("is", "empty_array") }

    /// [is](https://www.storyblok.com/docs/api/content-delivery/v2/filter-queries/operation-is)
    /// `not_empty_array`: the field holds at least one entry.
    public var isNotEmpty: Filter<Content> { filter("is", "not_empty_array") }
}

extension QueryField where Value == [String]? {
    public func contains(allOf values: [String]) -> Filter<Content> {
        filter("all_in_array", values.joined(separator: ","))
    }
    public func contains(anyOf values: [String]) -> Filter<Content> {
        filter("any_in_array", values.joined(separator: ","))
    }
    public var isEmpty: Filter<Content> { filter("is", "empty_array") }
    public var isNotEmpty: Filter<Content> { filter("is", "not_empty_array") }
}

// MARK: - Comparisons

/// Formats a `Double` the same way on every platform, so the query — and the cache entry its URL
/// selects — does not depend on the host's default description.
func decimalOperand(_ value: Double) -> String {
    value == value.rounded() && value.magnitude < 1e15
        ? String(format: "%.1f", value)
        : String(value)
}

/// `gt_int` — the whole-number field is greater than `value`.
public func > <Content, Value : BinaryInteger>(field: QueryField<Content, Value>, value: Value) -> Filter<Content> {
    field.filter("gt_int", String(describing: value))
}

/// `lt_int` — the whole-number field is less than `value`.
public func < <Content, Value : BinaryInteger>(field: QueryField<Content, Value>, value: Value) -> Filter<Content> {
    field.filter("lt_int", String(describing: value))
}

/// `gt_int` — the optional whole-number field is greater than `value`.
public func > <Content, Value : BinaryInteger>(field: QueryField<Content, Value?>, value: Value) -> Filter<Content> {
    field.filter("gt_int", String(describing: value))
}

/// `lt_int` — the optional whole-number field is less than `value`.
public func < <Content, Value : BinaryInteger>(field: QueryField<Content, Value?>, value: Value) -> Filter<Content> {
    field.filter("lt_int", String(describing: value))
}

/// `gt_float` — the decimal field is greater than `value`.
public func > <Content>(field: QueryField<Content, Double>, value: Double) -> Filter<Content> {
    field.filter("gt_float", decimalOperand(value))
}

/// `lt_float` — the decimal field is less than `value`.
public func < <Content>(field: QueryField<Content, Double>, value: Double) -> Filter<Content> {
    field.filter("lt_float", decimalOperand(value))
}

/// `gt_float` — the optional decimal field is greater than `value`.
public func > <Content>(field: QueryField<Content, Double?>, value: Double) -> Filter<Content> {
    field.filter("gt_float", decimalOperand(value))
}

/// `lt_float` — the optional decimal field is less than `value`.
public func < <Content>(field: QueryField<Content, Double?>, value: Double) -> Filter<Content> {
    field.filter("lt_float", decimalOperand(value))
}

/// `gt_date` — the date field is after `value`.
public func > <Content>(field: QueryField<Content, Date>, value: Date) -> Filter<Content> {
    field.filter("gt_date", value.wireValue)
}

/// `lt_date` — the date field is before `value`.
public func < <Content>(field: QueryField<Content, Date>, value: Date) -> Filter<Content> {
    field.filter("lt_date", value.wireValue)
}

/// `gt_date` — the optional date field is after `value`.
public func > <Content>(field: QueryField<Content, Date?>, value: Date) -> Filter<Content> {
    field.filter("gt_date", value.wireValue)
}

/// `lt_date` — the optional date field is before `value`.
public func < <Content>(field: QueryField<Content, Date?>, value: Date) -> Filter<Content> {
    field.filter("lt_date", value.wireValue)
}

/// `gt_int` — the text field, read as a whole number, is greater than `value`.
public func > <Content>(field: QueryField<Content, WholeNumberText>, value: Int) -> Filter<Content> {
    field.filter("gt_int", String(value))
}

public func < <Content>(field: QueryField<Content, WholeNumberText>, value: Int) -> Filter<Content> {
    field.filter("lt_int", String(value))
}

/// `gt_float` — the text field, read as a decimal, is greater than `value`.
public func > <Content>(field: QueryField<Content, DecimalText>, value: Double) -> Filter<Content> {
    field.filter("gt_float", decimalOperand(value))
}

public func < <Content>(field: QueryField<Content, DecimalText>, value: Double) -> Filter<Content> {
    field.filter("lt_float", decimalOperand(value))
}
