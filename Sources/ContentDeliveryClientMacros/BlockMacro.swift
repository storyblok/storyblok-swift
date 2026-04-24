import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct BlockMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard declaration.is(StructDeclSyntax.self) else {
            context.diagnose(Diagnostic(
                node: node,
                message: BlockLibraryMacroDiagnostic(
                    message: "@Block can only be applied to a struct",
                    id: MessageID(domain: "ContentDeliveryClientMacros", id: "blockNotAStruct"),
                    severity: .error
                )
            ))
            return []
        }
        guard !protocols.isEmpty else { return [] }
        return [try ExtensionDeclSyntax("extension \(type.trimmed): ContentDeliveryClient.Block {}")]
    }
}
