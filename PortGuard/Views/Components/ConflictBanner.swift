import SwiftUI

/// Özellik 4 — Shows inline conflict/availability status when search text is a port number.
/// Appears between the search bar and the process list.
public struct ConflictBanner: View {
    public let port: Int
    public let conflictProcess: PortProcess?  // nil = port is free
    public let language: String
    public let onKill: (() -> Void)?

    public init(port: Int, conflictProcess: PortProcess?, language: String = "tr", onKill: (() -> Void)? = nil) {
        self.port            = port
        self.conflictProcess = conflictProcess
        self.language        = language
        self.onKill          = onKill
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: conflictProcess == nil ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundColor(conflictProcess == nil ? .green : .red)

            // Message
            VStack(alignment: .leading, spacing: 2) {
                if let proc = conflictProcess {
                    Text("Port \(port) " + "Port Meşgul".localized(language: language))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.red)
                    Text("\(proc.processName) (PID \(proc.pid)) " + "bu portu kullanıyor".localized(language: language) + " — \(proc.formattedMemory) RAM")
                        .font(.system(size: 11))
                        .foregroundColor(AppleTheme.secondaryLabel)
                } else {
                    Text("Port \(port) " + "Port Müsait ✓".localized(language: language))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.green)
                    Text("Bu port şu an herhangi bir süreç tarafından kullanılmıyor.".localized(language: language))
                        .font(.system(size: 11))
                        .foregroundColor(AppleTheme.secondaryLabel)
                }
            }

            Spacer()

            // Kill button (only when conflict exists)
            if let proc = conflictProcess, let onKill = onKill, proc.isKillable {
                Button(action: onKill) {
                    Label("Sonlandır".localized(language: language), systemImage: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(conflictProcess == nil
                    ? Color.green.opacity(0.07)
                    : Color.red.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(conflictProcess == nil
                            ? Color.green.opacity(0.25)
                            : Color.red.opacity(0.25),
                            lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .transition(.asymmetric(
            insertion: .push(from: .top).combined(with: .opacity),
            removal: .push(from: .bottom).combined(with: .opacity)
        ))
    }
}
