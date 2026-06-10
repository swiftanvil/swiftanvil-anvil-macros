import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AnvilMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InjectableMacro.self,
        BenchmarkMacro.self
    ]
}
