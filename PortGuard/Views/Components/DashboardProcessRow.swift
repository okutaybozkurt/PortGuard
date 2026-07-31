import SwiftUI

public struct DashboardProcessRow: View {
    public let process: PortProcess
    public let onKill: () -> Void

    @State private var isHovered = false

    public init(process: PortProcess, onKill: @escaping () -> Void) {
        self.process = process
        self.onKill = onKill
    }

    public var body: some View {
        HStack(spacing: 16) {
            // Port Number
            Text(verbatim: "\(process.port)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .tracking(-0.4)
                .foregroundColor(.blue)
                .frame(width: 52, alignment: .leading)

            // Process Information
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if process.isDevProcess {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                            .help("Geliştirici servisi")
                    }
                    Text(process.processName)
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(-0.1)
                        .foregroundColor(AppleTheme.label)
                }

                HStack(spacing: 6) {
                    Text(verbatim: "PID \(process.pid) · \(process.user)")
                        .font(.system(size: 11))
                        .foregroundColor(AppleTheme.secondaryLabel)

                    Text(process.formattedUptime)
                        .appleBadgeStyle(color: process.isLongRunning ? .red : AppleTheme.secondaryLabel)
                        .help(process.isLongRunning ? "Uzun süredir açık — unutulmuş olabilir" : "Ne zamandır dinliyor")
                }
            }

            Spacer()

            // Resource Metrics (CPU & RAM)
            HStack(spacing: 20) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(process.formattedCPU)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(process.cpuPercent > 10.0 ? .purple : AppleTheme.label)
                    Text("CPU")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.4)
                        .foregroundColor(AppleTheme.secondaryLabel)
                }

                VStack(alignment: .trailing, spacing: 2) {
                    Text(process.formattedMemory)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(process.memoryMB >= 1024 ? .red : AppleTheme.label)
                    Text("RAM")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(0.4)
                        .foregroundColor(AppleTheme.secondaryLabel)
                }
            }
            .padding(.trailing, 4)

            // Kill Button
            if process.isKillable {
                Button(action: onKill) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.pressable)
                .help("\(process.processName) (\(process.port)) sürecini sonlandır")
            } else {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .help("Bu, birden fazla port/container'a hizmet eden paylaşılan bir sistem süreci — sonlandırılamaz.")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .appleCardStyle(hovered: isHovered)
        .onHover { hovering in
            withAnimation(.appleSpring) {
                isHovered = hovering
            }
        }
    }
}
