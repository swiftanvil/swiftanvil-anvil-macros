@_exported import AnvilMacrosPlugin
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
@testable import AnvilMacros

struct BenchmarkMacroTests {
    let macros: [String: Macro.Type] = [
        "Benchmark": BenchmarkMacro.self,
    ]

    @Test func benchmarkGeneratesDefaultIterations() {
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

            func benchmark_compute() -> BenchmarkMacroResult {
                let iterations = 1000
                var times: [Double] = []
                times.reserveCapacity(iterations)
                for _ in 0..<iterations {
                    let start = CFAbsoluteTimeGetCurrent()
                    _ = compute()
                    let end = CFAbsoluteTimeGetCurrent()
                    times.append(end - start)
                }
                return BenchmarkMacroResult(functionName: "compute", iterations: iterations, times: times)
            }
            """,
            macros: macros
        )
    }

    @Test func benchmarkGeneratesCustomIterations() {
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

            public func benchmark_work() -> BenchmarkMacroResult {
                let iterations = 500
                var times: [Double] = []
                times.reserveCapacity(iterations)
                for _ in 0..<iterations {
                    let start = CFAbsoluteTimeGetCurrent()
                    _ = work()
                    let end = CFAbsoluteTimeGetCurrent()
                    times.append(end - start)
                }
                return BenchmarkMacroResult(functionName: "work", iterations: iterations, times: times)
            }
            """,
            macros: macros
        )
    }

    @Test func benchmarkHandlesAsyncFunction() {
        assertMacroExpansion(
            """
            @Benchmark(iterations: 100)
            func fetch() async -> String {
                "data"
            }
            """,
            expandedSource: """
            func fetch() async -> String {
                "data"
            }

            func benchmark_fetch() async -> BenchmarkMacroResult {
                let iterations = 100
                var times: [Double] = []
                times.reserveCapacity(iterations)
                for _ in 0..<iterations {
                    let start = CFAbsoluteTimeGetCurrent()
                    _ = await fetch()
                    let end = CFAbsoluteTimeGetCurrent()
                    times.append(end - start)
                }
                return BenchmarkMacroResult(functionName: "fetch", iterations: iterations, times: times)
            }
            """,
            macros: macros
        )
    }

    @Test func benchmarkHandlesThrowsFunction() {
        assertMacroExpansion(
            """
            @Benchmark(iterations: 100)
            func risky() throws -> Int {
                42
            }
            """,
            expandedSource: """
            func risky() throws -> Int {
                42
            }

            func benchmark_risky() throws -> BenchmarkMacroResult {
                let iterations = 100
                var times: [Double] = []
                times.reserveCapacity(iterations)
                for _ in 0..<iterations {
                    let start = CFAbsoluteTimeGetCurrent()
                    do {
                        _ = try risky()
                    } catch {
                        times.append(CFAbsoluteTimeGetCurrent() - start)
                        continue
                    }
                    let end = CFAbsoluteTimeGetCurrent()
                    times.append(end - start)
                }
                return BenchmarkMacroResult(functionName: "risky", iterations: iterations, times: times)
            }
            """,
            macros: macros
        )
    }

    @Test func benchmarkHandlesAsyncThrowsFunction() {
        assertMacroExpansion(
            """
            @Benchmark(iterations: 50)
            func fetchData() async throws -> Data {
                Data()
            }
            """,
            expandedSource: """
            func fetchData() async throws -> Data {
                Data()
            }

            func benchmark_fetchData() async throws -> BenchmarkMacroResult {
                let iterations = 50
                var times: [Double] = []
                times.reserveCapacity(iterations)
                for _ in 0..<iterations {
                    let start = CFAbsoluteTimeGetCurrent()
                    do {
                        _ = try await fetchData()
                    } catch {
                        times.append(CFAbsoluteTimeGetCurrent() - start)
                        continue
                    }
                    let end = CFAbsoluteTimeGetCurrent()
                    times.append(end - start)
                }
                return BenchmarkMacroResult(functionName: "fetchData", iterations: iterations, times: times)
            }
            """,
            macros: macros
        )
    }
}

@Suite("BenchmarkMacroResult")
struct BenchmarkMacroResultTests {

    @Test("computes correct stats")
    func resultStats() {
        let result = BenchmarkMacroResult(
            functionName: "test",
            iterations: 5,
            times: [0.1, 0.2, 0.3, 0.4, 0.5]
        )

        #expect(result.min == 0.1)
        #expect(result.max == 0.5)
        #expect(result.mean == 0.3)
        #expect(result.median == 0.3)
        #expect(result.totalElapsed == 1.5)
        // stddev of [0.1, 0.2, 0.3, 0.4, 0.5] = sqrt(0.02) ≈ 0.1414
        #expect(result.stddev > 0.14 && result.stddev < 0.15)
    }

    @Test("handles empty times")
    func emptyTimes() {
        let result = BenchmarkMacroResult(
            functionName: "empty",
            iterations: 0,
            times: []
        )

        #expect(result.min == 0)
        #expect(result.max == 0)
        #expect(result.mean == 0)
        #expect(result.median == 0)
        #expect(result.stddev == 0)
    }

    @Test("handles single time")
    func singleTime() {
        let result = BenchmarkMacroResult(
            functionName: "single",
            iterations: 1,
            times: [0.42]
        )

        #expect(result.min == 0.42)
        #expect(result.max == 0.42)
        #expect(result.mean == 0.42)
        #expect(result.median == 0.42)
        #expect(result.stddev == 0)
    }

    @Test("median for even count")
    func medianEvenCount() {
        let result = BenchmarkMacroResult(
            functionName: "even",
            iterations: 4,
            times: [0.1, 0.2, 0.3, 0.4]
        )

        #expect(result.median == 0.25)
    }

    @Test("description contains key info")
    func descriptionContainsInfo() {
        let result = BenchmarkMacroResult(
            functionName: "compute",
            iterations: 100,
            times: [0.001, 0.002, 0.003]
        )

        let desc = result.description
        #expect(desc.contains("Benchmark: compute"))
        #expect(desc.contains("Iterations: 100"))
        #expect(desc.contains("Min:"))
        #expect(desc.contains("Mean:"))
        #expect(desc.contains("Median:"))
        #expect(desc.contains("StdDev:"))
    }
}
