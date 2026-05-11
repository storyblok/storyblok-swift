import SwiftCompilerPlugin
import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct BlockLibraryMacro {}

extension BlockLibraryMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: node,
                message: BlockLibraryMacroDiagnostic(
                    message: "@BlockLibrary can only be applied to an enum",
                    id: MessageID(domain: "ContentDeliveryClientMacros", id: "notAnEnum"),
                    severity: .error
                )
            ))
            return []
        }
        let enumName = enumDecl.name.text
        let nestedStructs = collectNestedStructs(in: declaration)
        let codingKeyMap = findCodingKeys(in: declaration)
        let cases = collectCases(in: declaration, codingKeyMap: codingKeyMap, nestedStructs: nestedStructs)

        let relations = computeRelations(cases: cases)

        let hasCodingKeys = declaration.memberBlock.members.contains { member in
            guard let enumDecl = member.decl.as(EnumDeclSyntax.self) else { return false }
            return enumDecl.name.text == "CodingKeys"
        }

        validateCaseAssociatedValues(in: declaration, nestedStructs: nestedStructs, context: context)
        validateNestedStructsHaveCases(nestedStructs: nestedStructs, cases: cases, in: declaration, context: context)
        validateStoryRelationTypes(enumName: enumName, in: cases, nestedStructs: nestedStructs, context: context)
        validateNestedStructsHaveBlockConformance(in: declaration, context: context)

        return [
            "static let relations: String = \(literal: relations)",
        ] + generateDecoding(cases: cases, enumName: enumName, nestedStructs: nestedStructs, generateCodingKeys: !hasCodingKeys)
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
            let ext = try ExtensionDeclSyntax("extension \(type.trimmed): ContentDeliveryClient.Block {}")
            extensions.append(ext)
        }

        return extensions
    }
}

// MARK: - Case collection

private struct CaseInfo {
    let caseName: String
    let componentName: String
    let params: [(label: String, type: TypeSyntax, unlabeled: Bool)]
    let nestedStructFields: [(label: String, type: TypeSyntax)]
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

private func collectCases(
    in declaration: some DeclGroupSyntax,
    codingKeyMap: [String: String],
    nestedStructs: [String: [(label: String, type: TypeSyntax)]]
) -> [CaseInfo] {
    var cases: [CaseInfo] = []
    for member in declaration.memberBlock.members {
        guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else { continue }
        for element in caseDecl.elements {
            let caseName = element.name.text
            let componentName = codingKeyMap[caseName] ?? caseName
            var params: [(label: String, type: TypeSyntax, unlabeled: Bool)] = []
            var nestedStructFields: [(label: String, type: TypeSyntax)] = []
            if let parameters = element.parameterClause?.parameters {
                let paramList = Array(parameters)
                // A single unlabeled param decodes the whole content as that type.
                if paramList.count == 1,
                   let param = paramList.first,
                   param.firstName == nil || param.firstName?.text == "_" {
                    params.append((label: "", type: param.type, unlabeled: true))
                    if let typeName = param.type.as(IdentifierTypeSyntax.self)?.name.text {
                        nestedStructFields = nestedStructs[typeName] ?? []
                    }
                } else {
                    for parameter in paramList {
                        guard let label = parameter.firstName?.text, label != "_" else { continue }
                        params.append((label: label, type: parameter.type, unlabeled: false))
                    }
                }
            }
            cases.append(CaseInfo(
                caseName: caseName,
                componentName: componentName,
                params: params,
                nestedStructFields: nestedStructFields
            ))
        }
    }
    return cases
}

// MARK: - Enum decoding generation

private func generateDecoding(
    cases: [CaseInfo],
    enumName: String,
    nestedStructs: [String: [(label: String, type: TypeSyntax)]],
    generateCodingKeys: Bool
) -> [DeclSyntax] {
    var switchCases = ""
    for c in cases {
        switchCases += "    case \"\(c.componentName)\":\n"
        if c.params.isEmpty {
            switchCases += "        self = .\(c.caseName)\n"
        } else {
            switchCases += generateCaseBody(c, enumName: enumName, nestedStructs: nestedStructs, allCases: cases)
        }
    }

    let initDecl: DeclSyntax = """
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let component = try container.decode(String.self, forKey: .component)
        switch component {
    \(raw: switchCases)    default:
            throw DecodingError.dataCorruptedError(forKey: .component, in: container, debugDescription: "Unknown component: \\(component)")
        }
    }
    """

    let helpers = generateUnwrapHelpers(cases: cases, enumName: enumName, nestedStructs: nestedStructs)
    guard generateCodingKeys else { return [initDecl] + helpers }

    let allLabels = Array(
        Set(["component"] + cases.flatMap { $0.params.filter { !$0.unlabeled }.map { $0.label } })
    ).sorted()
    let keyCases = allLabels.map { "    case \($0)" }.joined(separator: "\n")

    let codingKeysDecl: DeclSyntax = """
    enum CodingKeys: String, CodingKey {
    \(raw: keyCases)
    }
    """

    return [initDecl, codingKeysDecl] + helpers
}

/// Generates private static unwrap helpers for each unique nested-struct Story type referenced in cases.
private func generateUnwrapHelpers(
    cases: [CaseInfo],
    enumName: String,
    nestedStructs: [String: [(label: String, type: TypeSyntax)]]
) -> [DeclSyntax] {
    var seen = Set<String>()
    var helpers: [DeclSyntax] = []
    for c in cases {
        for param in c.params
            where !param.unlabeled
                && isStoryType(param.type)
                && storyTypeArgIsNestedStruct(param.type, nestedStructs: nestedStructs)
        {
            let structName = storyTypeArgument(param.type)!
            guard !seen.contains(structName) else { continue }
            seen.insert(structName)
            let matchCase = caseNameForNestedStruct(structName, allCases: cases)
            let helper: DeclSyntax = """
            private static func _unwrap\(raw: structName)(_ story: Story<\(raw: enumName)>) throws -> Story<\(raw: structName)> {
                guard case .\(raw: matchCase)(let content) = story.content else {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected .\(raw: matchCase) but got: \\(story.content)"))
                }
                return Story(story, content: content)
            }
            """
            helpers.append(helper)
        }
    }
    return helpers
}

/// Returns the body lines for one switch case (indented 8 spaces, ending with newline).
private func generateCaseBody(
    _ c: CaseInfo,
    enumName: String,
    nestedStructs: [String: [(label: String, type: TypeSyntax)]],
    allCases: [CaseInfo]
) -> String {
    let indent = "        "

    // Single unlabeled param: decode the whole content as that type
    if c.params.count == 1, c.params[0].unlabeled {
        return "\(indent)self = .\(c.caseName)(try \(c.params[0].type.trimmedDescription)(from: decoder))\n"
    }

    // Find the first labeled param that is Story<NestedStruct>
    let nestedStoryParam = c.params.first {
        !$0.unlabeled
            && isStoryType($0.type)
            && storyTypeArgIsNestedStruct($0.type, nestedStructs: nestedStructs)
    }

    guard let nestedParam = nestedStoryParam else {
        // No nested-struct Story params — standard multi-arg decode
        return generateStandardCaseBody(c, indent: indent)
    }

    let storyArg = storyTypeArgument(nestedParam.type)!
    let matchCaseName = caseNameForNestedStruct(storyArg, allCases: allCases)
    let isArray = isArrayStoryType(nestedParam.type)

    var body = ""

    if isArray {
        // Decode as [Story<EnumName>], then .map with pattern match
        body += "\(indent)let \(nestedParam.label) = try container.decode([Story<\(enumName)>].self, forKey: .\(nestedParam.label))\n"
        body += buildSelfAssignmentWithArray(
            c, nestedParam: nestedParam, matchCaseName: matchCaseName,
            storyArg: storyArg, enumName: enumName, nestedStructs: nestedStructs,
            allCases: allCases, indent: indent
        )
    } else {
        // Decode as Story<EnumName>, then if-case
        body += "\(indent)let \(nestedParam.label) = try container.decode(Story<\(enumName)>.self, forKey: .\(nestedParam.label))\n"
        body += buildSelfAssignmentWithSingle(
            c, nestedParam: nestedParam, matchCaseName: matchCaseName,
            storyArg: storyArg, enumName: enumName, nestedStructs: nestedStructs,
            allCases: allCases, indent: indent
        )
    }

    return body
}

/// Generates `self = .case(...)` with the array Story param replaced by a `.map { }` expression.
private func buildSelfAssignmentWithArray(
    _ c: CaseInfo,
    nestedParam: (label: String, type: TypeSyntax, unlabeled: Bool),
    matchCaseName: String,
    storyArg: String,
    enumName: String,
    nestedStructs: [String: [(label: String, type: TypeSyntax)]],
    allCases: [CaseInfo],
    indent: String
) -> String {
    let mapBody = "try \(nestedParam.label).map { try Self._unwrap\(storyArg)($0) }"

    let labeledParams = c.params.filter { !$0.unlabeled }
    if labeledParams.count == 1 {
        return "\(indent)self = .\(c.caseName)(\(nestedParam.label): \(mapBody))\n"
    }

    var args: [String] = []
    for param in labeledParams {
        if param.label == nestedParam.label {
            args.append("            \(param.label): \(mapBody)")
        } else {
            args.append("            \(simpleDecodeExpr(param))")
        }
    }
    return "\(indent)self = .\(c.caseName)(\n\(args.joined(separator: ",\n"))\n\(indent))\n"
}

/// Generates `if case .match(let content) = param.content { self = .case(...) } else { throw }`.
private func buildSelfAssignmentWithSingle(
    _ c: CaseInfo,
    nestedParam: (label: String, type: TypeSyntax, unlabeled: Bool),
    matchCaseName: String,
    storyArg: String,
    enumName: String,
    nestedStructs: [String: [(label: String, type: TypeSyntax)]],
    allCases: [CaseInfo],
    indent: String
) -> String {
    let labeledParams = c.params.filter { !$0.unlabeled }
    if labeledParams.count == 1 {
        return "\(indent)self = .\(c.caseName)(\(nestedParam.label): try Self._unwrap\(storyArg)(\(nestedParam.label)))\n"
    }
    var args: [String] = []
    for param in labeledParams {
        if param.label == nestedParam.label {
            args.append("            \(param.label): try Self._unwrap\(storyArg)(\(param.label))")
        } else {
            args.append("            \(simpleDecodeExpr(param))")
        }
    }
    return "\(indent)self = .\(c.caseName)(\n\(args.joined(separator: ",\n"))\n\(indent))\n"
}

/// Standard multi-arg case body where no nested-struct Story unwrapping is needed.
private func generateStandardCaseBody(_ c: CaseInfo, indent: String) -> String {
    let args = c.params.map { param -> String in
        if param.unlabeled {
            return "try \(param.type.trimmedDescription)(from: decoder)"
        }
        return simpleDecodeExpr(param)
    }
    if args.count == 1 {
        return "\(indent)self = .\(c.caseName)(\(args[0]))\n"
    }
    let joined = args.map { "            \($0)" }.joined(separator: ",\n")
    return "\(indent)self = .\(c.caseName)(\n\(joined)\n\(indent))\n"
}

/// Returns a `label: try container.decode(...)` expression string (no trailing comma/newline).
private func simpleDecodeExpr(_ param: (label: String, type: TypeSyntax, unlabeled: Bool)) -> String {
    let baseType = "\(unwrapOptional(param.type).trimmed)"
    if isOptionalType(param.type) {
        return "\(param.label): try container.decodeIfPresent(\(baseType).self, forKey: .\(param.label))"
    }
    return "\(param.label): try container.decode(\(baseType).self, forKey: .\(param.label))"
}

// MARK: - Helpers

private func computeRelations(cases: [CaseInfo]) -> String {
    Set(
        cases.flatMap { c -> [String] in
            let fromParams = c.params
                .filter { isStoryType($0.type) && !$0.unlabeled }
                .map { "\(c.componentName).\($0.label)" }
            let fromNested = c.nestedStructFields
                .filter { isStoryType($0.type) }
                .map { "\(c.componentName).\($0.label)" }
            return fromParams + fromNested
        }
    ).sorted().joined(separator: ",")
}

private func findCodingKeys(in declaration: some DeclGroupSyntax) -> [String: String] {
    var result: [String: String] = [:]
    for member in declaration.memberBlock.members {
        guard let enumDecl = member.decl.as(EnumDeclSyntax.self),
              enumDecl.name.text == "CodingKeys"
        else { continue }
        for caseMember in enumDecl.memberBlock.members {
            guard let caseDecl = caseMember.decl.as(EnumCaseDeclSyntax.self) else { continue }
            for element in caseDecl.elements {
                let name = element.name.text
                if let literal = element.rawValue?.value.as(StringLiteralExprSyntax.self),
                   literal.segments.count == 1,
                   let segment = literal.segments.first?.as(StringSegmentSyntax.self) {
                    result[name] = segment.content.text
                } else {
                    result[name] = name
                }
            }
        }
        break
    }
    return result
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

private func isArrayStoryType(_ type: TypeSyntax) -> Bool {
    if let array = type.as(ArrayTypeSyntax.self),
       let element = array.element.as(IdentifierTypeSyntax.self),
       element.name.text == "Story" {
        return true
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
        return arg.argument.trimmedDescription
    }
    if let array = type.as(ArrayTypeSyntax.self),
       let element = array.element.as(IdentifierTypeSyntax.self),
       element.name.text == "Story",
       let arg = element.genericArgumentClause?.arguments.first {
        return arg.argument.trimmedDescription
    }
    if let optional = type.as(OptionalTypeSyntax.self) {
        return storyTypeArgument(optional.wrappedType)
    }
    return nil
}

/// Returns true if the Story<T> type argument is a key in `nestedStructs`.
private func storyTypeArgIsNestedStruct(
    _ type: TypeSyntax,
    nestedStructs: [String: [(label: String, type: TypeSyntax)]]
) -> Bool {
    guard let arg = storyTypeArgument(type) else { return false }
    return nestedStructs[arg] != nil
}

/// Returns the case name of the enum case whose single unlabeled param is of type `structName`.
private func caseNameForNestedStruct(_ structName: String, allCases: [CaseInfo]) -> String {
    allCases.first {
        $0.params.count == 1 &&
        $0.params[0].unlabeled &&
        $0.params[0].type.trimmedDescription == structName
    }?.caseName ?? structName.lowercased()
}

private func structHasBlockConformance(_ structDecl: StructDeclSyntax) -> Bool {
    structDecl.inheritanceClause?.inheritedTypes.contains {
        $0.type.trimmedDescription == "Block"
    } ?? false
}

// MARK: - Validation

/// Each Story<T> labeled param must use the enclosing enum type or a nested struct type.
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
                        message: "Story<T> relation field type '\(typeArg)' must be the enclosing enum type or a nested struct type declared within the enum",
                        id: MessageID(domain: "ContentDeliveryClientMacros", id: "invalidRelationType"),
                        severity: .error
                    )
                ))
            }
        }
    }
}

/// Every nested struct must carry the @Block attribute or declare ': Block' inline.
private func validateNestedStructsHaveBlockConformance(
    in declaration: some DeclGroupSyntax,
    context: some MacroExpansionContext
) {
    for member in declaration.memberBlock.members {
        guard let structDecl = member.decl.as(StructDeclSyntax.self) else { continue }
        let hasBlockAttribute = structDecl.attributes.contains {
            guard case .attribute(let attr) = $0 else { return false }
            return attr.attributeName.trimmedDescription == "Block"
        }
        let hasBlockConformance = structHasBlockConformance(structDecl)
        if !hasBlockAttribute && !hasBlockConformance {
            context.diagnose(Diagnostic(
                node: structDecl.name,
                message: BlockLibraryMacroDiagnostic(
                    message: "nested struct '\(structDecl.name.text)' must conform to Block; apply the @Block macro or declare ': Block'",
                    id: MessageID(domain: "ContentDeliveryClientMacros", id: "nestedStructMissingBlock"),
                    severity: .error
                )
            ))
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
                            id: MessageID(domain: "ContentDeliveryClientMacros", id: "unlabeledMultiParam"),
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
                        id: MessageID(domain: "ContentDeliveryClientMacros", id: "unlabeledNonStruct"),
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
                        id: MessageID(domain: "ContentDeliveryClientMacros", id: "unlabeledNotNestedStruct"),
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
                    message: "nested struct '\(structName)' must have a corresponding enum case with it as an unlabeled associated value",
                    id: MessageID(domain: "ContentDeliveryClientMacros", id: "nestedStructMissingCase"),
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
struct ContentDeliveryClientPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [BlockLibraryMacro.self, BlockMacro.self]
}
