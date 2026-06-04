# AnvilMacros

Compile-time code generation macros for SwiftAnvil.

## Requirements

- Swift 5.9+
- macOS 15+ | iOS 18+ | tvOS 18+ | watchOS 11+ | visionOS 2+

## Macros

### `@AnvilInjectable`

Attached member macro that synthesizes a memberwise `init` for dependency injection.

```swift
import AnvilMacros

@AnvilInjectable
public struct Service {
    let repository: Repository
    let client: Client
}

// expands to:
// public init(repository: Repository, client: Client) {
//     self.repository = repository
//     self.client = client
// }
```

### `@Benchmark`

Attached peer macro that generates a benchmark wrapper function.

```swift
import AnvilMacros

@Benchmark(iterations: 1000)
func compute() -> Int {
    42
}

// expands to:
// func benchmark_compute() {
//     for _ in 0..<1000 {
//         _ = compute()
//     }
// }
```

## Installation

Add the package dependency to `Package.swift`:

```swift
.package(url: "https://github.com/swiftanvil/anvil-macros.git", from: "0.1.0"),
```

Then add `AnvilMacros` to your target dependencies.

## Development

```bash
swift build
swift test
```
