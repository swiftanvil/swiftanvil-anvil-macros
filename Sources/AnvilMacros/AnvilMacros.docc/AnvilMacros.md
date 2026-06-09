# ``AnvilMacros``

Compile-time code generation macros for the SwiftAnvil ecosystem.

## Overview

AnvilMacros provides Swift macros that reduce boilerplate and add compile-time safety:

- ``AnvilInjectable()`` — Synthesizes a memberwise `init` for dependency injection
- ``Benchmark(iterations:)`` — Generates a benchmark wrapper with timing statistics

## Topics

### Dependency Injection

- ``AnvilInjectable()``

### Performance

- ``Benchmark(iterations:)``
- ``BenchmarkMacroResult``
