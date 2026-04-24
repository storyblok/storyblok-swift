import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import ContentDeliveryClientMacros

private let macros: [String: Macro.Type] = ["Block": BlockMacro.self]

final class BlockMacroTests: XCTestCase {

    func test_blockMacroAddsBlockConformance() {
        assertMacroExpansion(
            """
            @Block
            struct Article: Decodable {
                let title: String
            }
            """,
            expandedSource: """
            struct Article: Decodable {
                let title: String
            }
            """,
            macros: macros
        )
    }

    func test_blockMacroErrorWhenAppliedToEnum() {
        assertMacroExpansion(
            """
            @Block
            enum Foo {
                case bar
            }
            """,
            expandedSource: """
            enum Foo {
                case bar
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Block can only be applied to a struct",
                    line: 1,
                    column: 1
                ),
            ],
            macros: macros
        )
    }
}
