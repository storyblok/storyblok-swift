import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct BlockLibraryMacro {}

extension BlockLibraryMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: node,
                message: BlockLibraryMacroDiagnostic(
                    message: "@BlockLibrary can only be applied to an enum",
                    id: MessageID(domain: "StoryblokClientMacros", id: "notAnEnum"),
                    severity: .error
                )
            ))
            return []
        }
        let enumName = enumDecl.name.text
        let nestedStructs = collectNestedStructs(in: declaration)
        let nestedStructCodingKeys = collectNestedStructCodingKeys(in: declaration)
        let codingKeyMap = findCodingKeys(in: declaration)
        let cases = collectCases(
            in: declaration,
            codingKeyMap: codingKeyMap,
            nestedStructs: nestedStructs,
            nestedStructCodingKeys: nestedStructCodingKeys
        )

        let relations = computeRelations(cases: cases)

        validateCaseAssociatedValues(in: declaration, nestedStructs: nestedStructs, context: context)
        validateNestedStructsHaveCases(nestedStructs: nestedStructs, cases: cases, in: declaration, context: context)
        validateStoryRelationTypes(enumName: enumName, in: cases, nestedStructs: nestedStructs, context: context)

        return [
            "nonisolated static let relations: String = \(literal: relations)",
        ] + generateDecoding(cases: cases, enumName: enumName)
    }
}

extension BlockLibraryMacro: ExtensionMacro {

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(EnumDeclSyntax.self) else { return [] }

        var extensions: [ExtensionDeclSyntax] = []

        if !protocols.isEmpty {
            let ext = try ExtensionDeclSyntax("nonisolated extension \(type.trimmed): BlockLibrary {}")
            extensions.append(ext)
        }

        return extensions
    }
}

// MARK: - Case collection

private struct CaseInfo {
    /// The Swift case identifier as written, including any backticks (e.g. `` `default` ``).
    /// Used when emitting `.caseName` references so escaped keywords stay valid Swift.
    let caseName: String
    let componentName: String
    let params: [(label: String, type: TypeSyntax, unlabeled: Bool)]
    let nestedStructFields: [(label: String, type: TypeSyntax)]
    let nestedStructCodingKeyMap: [String: String]  // Swift label → JSON key from the nested struct's CodingKeys
    let perCaseCodingKeyMap: [String: String]  // Swift label → JSON key; empty = no override
    /// Name of the per-case CodingKeys type, derived from the backtick-stripped case name.
    let codingKeysTypeName: String
}

/// Removes the enclosing backticks from an escaped Swift identifier (e.g. `` `default` `` → `default`).
private func strippingBackticks(_ name: String) -> String {
    guard name.count >= 2, name.hasPrefix("`"), name.hasSuffix("`") else { return name }
    return String(name.dropFirst().dropLast())
}

/// Derives the per-case CodingKeys type name from a case name. Backtick escaping is removed and
/// any characters that aren't valid in a Swift identifier (e.g. the hyphens in a raw identifier
/// like `` `emoji-randomizer` ``) are treated as word separators, yielding a PascalCase identifier
/// (`EmojiRandomizerCodingKeys`). Plain and camelCase names keep their existing shape
/// (`article` → `ArticleCodingKeys`, `popularArticles` → `PopularArticlesCodingKeys`).
private func codingKeysTypeName(forCase caseName: String) -> String {
    let bare = strippingBackticks(caseName)
    var result = ""
    var capitalizeNext = true
    for ch in bare {
        if ch == "_" || ch.isLetter || ch.isNumber {
            result.append(capitalizeNext && ch.isLetter ? Character(ch.uppercased()) : ch)
            capitalizeNext = false
        } else {
            capitalizeNext = true
        }
    }
    return result + "CodingKeys"
}

private func collectNestedStructs(
    in declaration: some DeclGroupSyntax
) -> [String: [(label: String, type: TypeSyntax)]] {
    var result: [String: [(label: String, type: TypeSyntax)]] = [:]
    for member in declaration.memberBlock.members {
        guard let structDecl = member.decl.as(StructDeclSyntax.self) else { continue }
        var fields: [(label: String, type: TypeSyntax)] = []
        for structMember in structDecl.memberBlock.members {
            guard let varDecl = structMember.decl.as(VariableDeclSyntax.self) else { continue }
            for binding in varDecl.bindings {
                guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                      let type = binding.typeAnnotation?.type,
                      binding.accessorBlock == nil
                else { continue }
                fields.append((label: name, type: type))
            }
        }
        result[structDecl.name.text] = fields
    }
    return result
}

/// Collects the `CodingKeys` mapping (Swift name → JSON key) declared inside each nested struct,
/// so relation paths can use the JSON key when a struct remaps a relation field.
private func collectNestedStructCodingKeys(
    in declaration: some DeclGroupSyntax
) -> [String: [String: String]] {
    var result: [String: [String: String]] = [:]
    for member in declaration.memberBlock.members {
        guard let structDecl = member.decl.as(StructDeclSyntax.self) else { continue }
        for structMember in structDecl.memberBlock.members {
            guard let enumDecl = structMember.decl.as(EnumDeclSyntax.self),
                  enumDecl.name.text == "CodingKeys"
            else { continue }
            result[structDecl.name.text] = parseCodingKeys(from: enumDecl)
            break
        }
    }
    return result
}

private func collectCases(
    in declaration: some DeclGroupSyntax,
    codingKeyMap: [String: String],
    nestedStructs: [String: [(label: String, type: TypeSyntax)]],
    nestedStructCodingKeys: [String: [String: String]]
) -> [CaseInfo] {
    var cases: [CaseInfo] = []
    for member in declaration.memberBlock.members {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
        for element in caseDecl.elements {
            let caseName = element.name.text
            let logicalName = strippingBackticks(caseName)
            let componentName = codingKeyMap[logicalName] ?? logicalName
            var params: [(label: String, type: TypeSyntax, unlabeled: Bool)] = []
            var nestedStructFields: [(label: String, type: TypeSyntax)] = []
            var nestedStructCodingKeyMap: [String: String] = [:]
            if let parameters = element.parameterClause?.parameters {
                let paramList = Array(parameters)
                // A single unlabeled param decodes the whole content as that type.
                if paramList.count == 1,
                   let param = paramList.first,
                   param.firstName == nil || param.firstName?.text == "_" {
                    params.append((label: "", type: param.type, unlabeled: true))
                    if let typeName = param.type.as(IdentifierTypeSyntax.self)?.name.text {
                        nestedStructFields = nestedStructs[typeName] ?? []
                        nestedStructCodingKeyMap = nestedStructCodingKeys[typeName] ?? [:]
                    }
                } else {
                    for parameter in paramList {
                        guard let label = parameter.firstName?.text, label != "_" else { continue }
                        params.append((label: label, type: parameter.type, unlabeled: false))
                    }
                }
            }
            let perCaseCodingKeyMap = findPerCaseCodingKeys(caseName: logicalName, in: declaration)
            cases.append(CaseInfo(
                caseName: caseName,
                componentName: componentName,
                params: params,
                nestedStructFields: nestedStructFields,
                nestedStructCodingKeyMap: nestedStructCodingKeyMap,
                perCaseCodingKeyMap: perCaseCodingKeyMap,
                codingKeysTypeName: codingKeysTypeName(forCase: caseName)
            ))
        }
    }
    return cases
}

// MARK: - Enum decoding generation

private func generateDecoding(
    cases: [CaseInfo],
    enumName: String
) -> [DeclSyntax] {
    let containerTypeName = "\(enumName)CodingKeys"

    // A `case unknown` (no associated values) acts as a catch-all for unrecognised
    // component names. When present the default branch silently assigns it instead
    // of throwing, which prevents decoding failures when the API returns components
    // the client doesn't know about yet.
    let unknownCase = cases.first { $0.caseName == "unknown" && $0.params.isEmpty }
    let knownCases  = cases.filter { $0.caseName != "unknown" }

    var switchCases = ""
    for c in knownCases {
        switchCases += "    case \"\(c.componentName)\":\n"
        if c.params.isEmpty {
            switchCases += "        self = .\(c.caseName)\n"
        } else {
            switchCases += generateCaseBody(c)
        }
    }

    let defaultClause = unknownCase != nil
        ? "    default:\n        self = .unknown\n"
        : "    default:\n        throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: \"Unknown component: \\(component)\")\n"

    let initDecl: DeclSyntax = """
    nonisolated init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: \(raw: containerTypeName).self)
        let component = try container.decode(String.self, forKey: .component)
        switch component {
    \(raw: switchCases)\(raw: defaultClause)}
    }
    """

    let autoPerCaseDecls = generatePerCaseCodingKeyDecls(cases: cases)

    let codingKeysDecl: DeclSyntax = """
    enum \(raw: containerTypeName): String, CodingKey {
        case component
    }
    """

    return [initDecl, codingKeysDecl] + autoPerCaseDecls
}

private func generatePerCaseCodingKeyDecls(cases: [CaseInfo]) -> [DeclSyntax] {
    var decls: [DeclSyntax] = []
    for c in cases {
        let labeledParams = c.params.filter { !$0.unlabeled }
        guard !labeledParams.isEmpty, c.perCaseCodingKeyMap.isEmpty else { continue }
        let enumName = c.codingKeysTypeName
        let keyCases = labeledParams.map { $0.label }.sorted().map { "    case \($0)" }.joined(separator: "\n")
        let decl: DeclSyntax = """
        enum \(raw: enumName): String, CodingKey {
        \(raw: keyCases)
        }
        """
        decls.append(decl)
    }
    return decls
}

/// Returns the body lines for one switch case (indented 8 spaces, ending with newline).
private func generateCaseBody(_ c: CaseInfo) -> String {
    let indent = "        "
    if c.params.count == 1, c.params[0].unlabeled {
        return "\(indent)self = .\(c.caseName)(try \(c.params[0].type.trimmedDescription)(from: decoder))\n"
    }
    return generatePerCaseCodingKeyBody(c, indent: indent)
}

private func generatePerCaseCodingKeyBody(_ c: CaseInfo, indent: String) -> String {
    let containerTypeName = c.codingKeysTypeName
    var lines = "\(indent)let caseContainer = try decoder.container(keyedBy: \(containerTypeName).self)\n"
    let args = c.params.map { param -> String in
        let baseType = "\(unwrapOptional(param.type).trimmed)"
        if isOptionalType(param.type) {
            return "\(param.label): try caseContainer.decodeIfPresent(\(baseType).self, forKey: .\(param.label))"
        }
        return "\(param.label): try caseContainer.decode(\(baseType).self, forKey: .\(param.label))"
    }
    if args.count == 1 {
        lines += "\(indent)self = .\(c.caseName)(\(args[0]))\n"
    } else {
        let joined = args.map { "            \($0)" }.joined(separator: ",\n")
        lines += "\(indent)self = .\(c.caseName)(\n\(joined)\n\(indent))\n"
    }
    return lines
}

// MARK: - Helpers

private func computeRelations(cases: [CaseInfo]) -> String {
    Set(
        cases.flatMap { c -> [String] in
            let fromParams = c.params
                .filter { isStoryType($0.type) && !$0.unlabeled }
                .map { "\(c.componentName).\(c.perCaseCodingKeyMap[$0.label] ?? $0.label)" }
            let fromNested = c.nestedStructFields
                .filter { isStoryType($0.type) }
                .map { "\(c.componentName).\(c.nestedStructCodingKeyMap[$0.label] ?? $0.label)" }
            return fromParams + fromNested
        }
    ).sorted().joined(separator: ",")
}

/// Parses a `CodingKeys`-style enum into a Swift-name → JSON-key map. Cases without a string
/// raw value map to themselves.
private func parseCodingKeys(from enumDecl: EnumDeclSyntax) -> [String: String] {
    var result: [String: String] = [:]
    for caseMember in enumDecl.memberBlock.members {
        guard let caseDecl = caseMember.decl.as(EnumCaseDeclSyntax.self) else { continue }
        for element in caseDecl.elements {
            let name = strippingBackticks(element.name.text)
            if let literal = element.rawValue?.value.as(StringLiteralExprSyntax.self),
               literal.segments.count == 1,
               let segment = literal.segments.first?.as(StringSegmentSyntax.self) {
                result[name] = segment.content.text
            } else {
                result[name] = name
            }
        }
    }
    return result
}

private func findCodingKeys(in declaration: some DeclGroupSyntax) -> [String: String] {
    findCodingKeysEnum(named: "CodingKeys", in: declaration)
}

private func findPerCaseCodingKeys(
    caseName: String,
    in declaration: some DeclGroupSyntax
) -> [String: String] {
    findCodingKeysEnum(named: codingKeysTypeName(forCase: caseName), in: declaration)
}

private func findCodingKeysEnum(
    named targetName: String,
    in declaration: some DeclGroupSyntax
) -> [String: String] {
    for member in declaration.memberBlock.members {
        guard let enumDecl = member.decl.as(EnumDeclSyntax.self),
              enumDecl.name.text == targetName
        else { continue }
        return parseCodingKeys(from: enumDecl)
    }
    return [:]
}

private func isStoryType(_ type: TypeSyntax) -> Bool {
    if let identifier = type.as(IdentifierTypeSyntax.self), identifier.name.text == "Story" {
        return true
    }
    if let array = type.as(ArrayTypeSyntax.self),
       let element = array.element.as(IdentifierTypeSyntax.self),
       element.name.text == "Story" {
        return true
    }
    if let optional = type.as(OptionalTypeSyntax.self) {
        return isStoryType(optional.wrappedType)
    }
    return false
}

private func isOptionalType(_ type: TypeSyntax) -> Bool {
    type.is(OptionalTypeSyntax.self)
}

private func unwrapOptional(_ type: TypeSyntax) -> TypeSyntax {
    if let optional = type.as(OptionalTypeSyntax.self) {
        return optional.wrappedType
    }
    return type
}

/// Returns the type argument `T` from a `Story<T>`, `[Story<T>]`, or `Story<T>?` type.
private func storyTypeArgument(_ type: TypeSyntax) -> String? {
    if let id = type.as(IdentifierTypeSyntax.self), id.name.text == "Story",
       let arg = id.genericArgumentClause?.arguments.first {
        return arg.argument.as(TypeSyntax.self)?.trimmedDescription
    }
    if let array = type.as(ArrayTypeSyntax.self),
       let element = array.element.as(IdentifierTypeSyntax.self),
       element.name.text == "Story",
       let arg = element.genericArgumentClause?.arguments.first {
        return arg.argument.as(TypeSyntax.self)?.trimmedDescription
    }
    if let optional = type.as(OptionalTypeSyntax.self) {
        return storyTypeArgument(optional.wrappedType)
    }
    return nil
}

// MARK: - Validation

/// Story<T> labeled params must use the enclosing enum or a nested struct so the macro
/// can discover their Story fields and include them in the synthesized `relations` string.
private func validateStoryRelationTypes(
    enumName: String,
    in cases: [CaseInfo],
    nestedStructs: [String: [(label: String, type: TypeSyntax)]],
    context: some MacroExpansionContext
) {
    for c in cases {
        for param in c.params where !param.unlabeled && isStoryType(param.type) {
            guard let typeArg = storyTypeArgument(param.type) else { continue }
            let valid = typeArg == enumName || nestedStructs[typeArg] != nil
            if !valid {
                context.diagnose(Diagnostic(
                    node: param.type,
                    message: BlockLibraryMacroDiagnostic(
                        message: "Story<T> relation field type '\(typeArg)' must be the enclosing enum type or a nested struct declared within the enum; the macro can only discover nested Story fields for types defined in the enum body",
                        id: MessageID(domain: "StoryblokClientMacros", id: "invalidRelationType"),
                        severity: .error
                    )
                ))
            }
        }
    }
}

/// Every case's associated values must be all labeled, or exactly one unlabeled nested struct.
private func validateCaseAssociatedValues(
    in declaration: some DeclGroupSyntax,
    nestedStructs: [String: [(label: String, type: TypeSyntax)]],
    context: some MacroExpansionContext
) {
    for member in declaration.memberBlock.members {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
        for element in caseDecl.elements {
            guard let parameters = element.parameterClause?.parameters else { continue }
            let paramList = Array(parameters)
            guard !paramList.isEmpty else { continue }

            let unlabeled = paramList.filter {
                $0.firstName == nil || $0.firstName?.text == "_"
            }
            guard !unlabeled.isEmpty else { continue }

            if paramList.count > 1 {
                for param in unlabeled {
                    context.diagnose(Diagnostic(
                        node: param.type,
                        message: BlockLibraryMacroDiagnostic(
                            message: "associated values with multiple parameters must all have labels",
                            id: MessageID(domain: "StoryblokClientMacros", id: "unlabeledMultiParam"),
                            severity: .error
                        )
                    ))
                }
                continue
            }

            let type = unlabeled[0].type
            guard isPlainStructType(type) else {
                context.diagnose(Diagnostic(
                    node: type,
                    message: BlockLibraryMacroDiagnostic(
                        message: "a single unlabeled associated value must be a plain struct type",
                        id: MessageID(domain: "StoryblokClientMacros", id: "unlabeledNonStruct"),
                        severity: .error
                    )
                ))
                continue
            }

            let typeName = type.as(IdentifierTypeSyntax.self)!.name.text
            if nestedStructs[typeName] == nil {
                context.diagnose(Diagnostic(
                    node: type,
                    message: BlockLibraryMacroDiagnostic(
                        message: "'\(typeName)' must be declared as a nested struct within the enum",
                        id: MessageID(domain: "StoryblokClientMacros", id: "unlabeledNotNestedStruct"),
                        severity: .error
                    )
                ))
            }
        }
    }
}

/// Every nested struct must have a corresponding enum case with it as an unlabeled associated value.
private func validateNestedStructsHaveCases(
    nestedStructs: [String: [(label: String, type: TypeSyntax)]],
    cases: [CaseInfo],
    in declaration: some DeclGroupSyntax,
    context: some MacroExpansionContext
) {
    let unlabeledTypes = Set(
        cases.compactMap { c -> String? in
            guard let param = c.params.first, param.unlabeled else { return nil }
            return param.type.as(IdentifierTypeSyntax.self)?.name.text
        }
    )
    for member in declaration.memberBlock.members {
        guard let structDecl = member.decl.as(StructDeclSyntax.self) else { continue }
        let structName = structDecl.name.text
        if !unlabeledTypes.contains(structName) {
            context.diagnose(Diagnostic(
                node: structDecl.name,
                message: BlockLibraryMacroDiagnostic(
                    message: "nested struct '\(structName)' must have a corresponding enum case with it as an unlabeled associated value; the case name must match the block type's technical name",
                    id: MessageID(domain: "StoryblokClientMacros", id: "nestedStructMissingCase"),
                    severity: .error
                )
            ))
        }
    }
}

private func isPlainStructType(_ type: TypeSyntax) -> Bool {
    guard let identifier = type.as(IdentifierTypeSyntax.self) else { return false }
    return identifier.genericArgumentClause == nil
}

struct BlockLibraryMacroDiagnostic: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity

    init(message: String, id: MessageID, severity: DiagnosticSeverity) {
        self.message = message
        self.diagnosticID = id
        self.severity = severity
    }
}

@main
struct StoryblokClientPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [BlockLibraryMacro.self]
}
