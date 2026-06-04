@_exported import AnvilMacrosPlugin
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing


struct InjectableMacroTests {
    let macros: [String: Macro.Type] = [
        "AnvilInjectable": InjectableMacro.self,
    ]

    @Test func InjectableGeneratesMemberwiseInit() {
        assertMacroExpansion(
            """
            @AnvilInjectable
            public struct Service {
                let repository: Repository
                let client: Client
            }
            """,
            expandedSource: """
            public struct Service {
                let repository: Repository
                let client: Client

                public init(repository: Repository, client: Client) {
                    self.repository = repository
                    self.client = client
                }
            }
            """,
            macros: macros
        )
    }

    @Test func InjectableSkipsComputedProperties() {
        assertMacroExpansion(
            """
            @AnvilInjectable
            struct Container {
                let value: Int
                var doubled: Int { value * 2 }
            }
            """,
            expandedSource: """
            struct Container {
                let value: Int
                var doubled: Int { value * 2 }

                init(value: Int) {
                    self.value = value
                }
            }
            """,
            macros: macros
        )
    }
}
