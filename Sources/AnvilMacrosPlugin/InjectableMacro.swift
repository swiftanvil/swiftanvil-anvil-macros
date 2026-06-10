import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros

public struct InjectableMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: node,
                    message: SimpleDiagnosticMessage(
                        message: "@AnvilInjectable can only be applied to structs",
                        diagnosticID: .init(domain: "AnvilMacros", id: "invalidDeclaration"),
                        severity: .error
                    )
                )
            )
            return []
        }

        let storedProperties = structDecl.memberBlock.members.compactMap { member -> (name: String, type: String)? in
            guard
                let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.first,
                let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                let typeAnnotation = binding.typeAnnotation?.type.description
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            else {
                return nil
            }
            // Skip computed properties (no initializer and no accessor observed via syntax)
            // If accessor block is present, it's computed.
            if binding.accessorBlock != nil {
                return nil
            }
            return (name: identifier, type: typeAnnotation)
        }

        guard !storedProperties.isEmpty else {
            return []
        }

        let parameters = storedProperties
            .map { "\($0.name): \($0.type)" }
            .joined(separator: ", ")

        let assignments = storedProperties
            .map { "self.\($0.name) = \($0.name)" }
            .joined(separator: "\n    ")

        let accessModifier = structDecl.modifiers.accessModifier.map { "\($0) " } ?? ""

        let initDecl: DeclSyntax = """
        \(raw: accessModifier)init(\(raw: parameters)) {
            \(raw: assignments)
        }
        """

        return [initDecl]
    }
}

extension DeclModifierListSyntax {
    var accessModifier: String? {
        for modifier in self {
            let text = modifier.name.text
            if ["public", "internal", "fileprivate", "private", "package", "open"].contains(text) {
                return text
            }
        }
        return nil
    }
}
