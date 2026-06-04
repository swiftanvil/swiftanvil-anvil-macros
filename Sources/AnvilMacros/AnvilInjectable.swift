/// Generates a memberwise `init` for dependency injection.
///
/// Apply this macro to a struct to synthesize a public memberwise initializer
/// from its stored properties.
///
/// ```swift
/// @AnvilInjectable
/// public struct Service {
///     let repository: Repository
/// }
/// // expands to:
/// // public init(repository: Repository) { self.repository = repository }
/// ```
@attached(member, names: named(init))
public macro AnvilInjectable() = #externalMacro(module: "AnvilMacrosPlugin", type: "InjectableMacro")
