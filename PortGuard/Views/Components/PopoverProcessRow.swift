import SwiftUI

public struct PopoverProcessRow: View {
    public let process: PortProcess
    public let onKill: () -> Void

    @State private var isHovered = false

    public init(process: PortProcess, onKill: @escaping () -> Void) {
        self.process = process
        self.onKill = onKill
    }

    public var body: some View {
        HStack(spacing: 10) {
            // Port Badge
            Text(verbatim: ":\(process.port)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(-0.2)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.12))
                .foregroundColor(.blue)
                .cornerRadius(6)

            // Process Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if process.isDevProcess {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                    }
                    Text(process.processName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppleTheme.label)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Text(verbatim: "PID \(process.pid)")
                        .font(.system(size: 10))
                        .foregroundColor(AppleTheme.secondaryLabel)
                    Text("• \(process.formattedUptime)")
                        .font(.system(size: 10, weight: process.isLongRunning ? .bold : .regular))
                        .foregroundColor(process.isLongRunning ? .red : AppleTheme.secondaryLabel)
                    if process.cpuPercent > 0.1 {
                        Text("• \(process.formattedCPU) CPU")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.purple)
                    }
                }
            }

            Spacer()

            // RAM Badge
            Text(process.formattedMemory)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(process.memoryMB >= 1024 ? Color.red.opacity(0.15) : Color.orange.opacity(0.12))
                .foregroundColor(process.memoryMB >= 1024 ? .red : .orange)
                .cornerRadius(5)

            // Kill Button
            if process.isKillable {
                Button(action: onKill) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.pressable)
                .help("\(process.processName) (\(process.port)) sürecini sonlandır")
            } else {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .help("Paylaşılan sistem süreci — sonlandırılamaz.")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.12) : Color.clear)
        .cornerRadius(8)
        .onHover { hovering in
            withAnimation(.appleSpring) {
                isHovered = hovering
            }
        }
    }
}
