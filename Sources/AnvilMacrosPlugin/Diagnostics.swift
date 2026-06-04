import SwiftDiagnostics
import SwiftSyntax

struct SimpleDiagnosticMessage: DiagnosticMessage {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity
}
