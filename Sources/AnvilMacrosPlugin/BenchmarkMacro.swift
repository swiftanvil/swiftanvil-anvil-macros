import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct BenchmarkMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: SimpleDiagnosticMessage(
                        message: "@Benchmark can only be applied to functions",
                        diagnosticID: .init(domain: "AnvilMacros", id: "invalidDeclaration"),
                        severity: .error
                    )
                )
            )
            return []
        }

        let funcName = funcDecl.name.text
        let benchmarkName = "benchmark_\(funcName)"

        // Default iterations = 1000
        var iterations = 1000

        if let arguments = node.arguments?.as(LabeledExprListSyntax.self) {
            for arg in arguments {
                if arg.label?.text == "iterations",
                   let literal = arg.expression.as(IntegerLiteralExprSyntax.self) {
                    iterations = Int(literal.literal.text) ?? 1000
                }
            }
        }

        let access = funcDecl.modifiers.accessModifier.map { "\($0) " } ?? ""

        let benchmarkDecl: DeclSyntax = """
        \(raw: access)func \(raw: benchmarkName)() {
            for _ in 0 ..< \(raw: iterations) {
                _ = \(raw: funcName)()
            }
        }
        """

        return [benchmarkDecl]
    }
}
