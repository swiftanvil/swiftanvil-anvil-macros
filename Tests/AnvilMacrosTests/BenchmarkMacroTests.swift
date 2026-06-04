@_exported import AnvilMacrosPlugin
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing


struct BenchmarkMacroTests {
    let macros: [String: Macro.Type] = [
        "Benchmark": BenchmarkMacro.self,
    ]

    @Test func BenchmarkGeneratesDefaultIterations() {
        assertMacroExpansion(
            """
            @Benchmark
            func compute() -> Int {
                42
            }
            """,
            expandedSource: """
            func compute() -> Int {
                42
            }

            func benchmark_compute() {
                for _ in 0..<1000 {
                    _ = compute()
                }
            }
            """,
            macros: macros
        )
    }

    @Test func BenchmarkGeneratesCustomIterations() {
        assertMacroExpansion(
            """
            @Benchmark(iterations: 500)
            public func work() {
                print("work")
            }
            """,
            expandedSource: """
            public func work() {
                print("work")
            }

            public func benchmark_work() {
                for _ in 0..<500 {
                    _ = work()
                }
            }
            """,
            macros: macros
        )
    }
}
