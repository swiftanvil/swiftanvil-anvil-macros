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
                if
                    arg.label?.text == "iterations",
                    let literal = arg.expression.as(IntegerLiteralExprSyntax.self)
                {
                    iterations = Int(literal.literal.text) ?? 1000
                }
            }
        }

        let access = funcDecl.modifiers.accessModifier.map { "\($0) " } ?? ""
        let isAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil
        let isThrows = funcDecl.signature.effectSpecifiers?.throwsClause != nil
        let isAsyncThrows = isAsync && isThrows

        // Build the function call
        let callPrefix = if isAsyncThrows {
            "try await \(funcName)()"
        } else if isAsync {
            "await \(funcName)()"
        } else if isThrows {
            "try \(funcName)()"
        } else {
            "\(funcName)()"
        }

        // Build the benchmark body
        let body = if isThrows {
            """
            let iterations = \(iterations)
            var times: [Double] = []
            times.reserveCapacity(iterations)
            for _ in 0..<iterations {
                let start = CFAbsoluteTimeGetCurrent()
                do {
                    _ = \(callPrefix)
                } catch {
                    times.append(CFAbsoluteTimeGetCurrent() - start)
                    continue
                }
                let end = CFAbsoluteTimeGetCurrent()
                times.append(end - start)
            }
            return BenchmarkMacroResult(functionName: "\(funcName)", iterations: iterations, times: times)
            """
        } else {
            """
            let iterations = \(iterations)
            var times: [Double] = []
            times.reserveCapacity(iterations)
            for _ in 0..<iterations {
                let start = CFAbsoluteTimeGetCurrent()
                _ = \(callPrefix)
                let end = CFAbsoluteTimeGetCurrent()
                times.append(end - start)
            }
            return BenchmarkMacroResult(functionName: "\(funcName)", iterations: iterations, times: times)
            """
        }

        let asyncKeyword = isAsync ? "async " : ""
        let throwsKeyword = isThrows ? "throws " : ""

        let benchmarkDecl: DeclSyntax = """
        \(raw: access)func \(raw: benchmarkName)() \(raw: asyncKeyword)\(raw: throwsKeyword)-> BenchmarkMacroResult {
            \(raw: body)
        }
        """

        return [benchmarkDecl]
    }
}
