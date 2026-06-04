/// Generates a benchmark wrapper for a function.
///
/// Apply this macro to a function to synthesize a peer function that runs
/// the original body repeatedly for benchmarking.
///
/// ```swift
/// @Benchmark(iterations: 1000)
/// func compute() -> Int { 42 }
/// // expands to:
/// // func benchmark_compute() {
/// //     for _ in 0..<1000 { _ = compute() }
/// // }
/// ```
@attached(peer, names: prefixed(benchmark_))
public macro Benchmark(iterations: Int = 1000) = #externalMacro(module: "AnvilMacrosPlugin", type: "BenchmarkMacro")
