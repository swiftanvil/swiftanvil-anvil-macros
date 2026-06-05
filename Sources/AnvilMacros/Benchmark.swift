/// Generates a benchmark wrapper that measures execution time and returns statistics.
///
/// Apply this macro to a zero-argument function to synthesize a peer function that runs
/// the original body repeatedly, captures timing for each iteration, and returns a
/// `BenchmarkMacroResult` with min, mean, median, and standard deviation.
///
/// ```swift
/// @Benchmark(iterations: 1000)
/// func compute() -> Int { 42 }
///
/// let result = benchmark_compute()
/// print(result.mean)   // average time per iteration
/// print(result.median) // median time
/// ```
///
/// The generated function is named `benchmark_<originalFunctionName>` and returns
/// `BenchmarkMacroResult`.
@attached(peer, names: prefixed(benchmark_))
public macro Benchmark(iterations: Int = 1000) = #externalMacro(module: "AnvilMacrosPlugin", type: "BenchmarkMacro")
