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
            // Icon / Port Box
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 65, height: 46)
                VStack(spacing: 1) {
                    Text("PORT")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.blue.opacity(0.8))
                    Text("\(process.port)")
                        .font(.system(.subheadline, design: .monospaced))
                        .bold()
                        .foregroundColor(.blue)
                }
            }

            // Process Details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(process.processName)
                        .font(.headline)
                        .bold()

                    if process.isDevProcess {
                        Text("DEV")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 12) {
                    Text("PID: \(process.pid)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Kullanıcı: \(process.user)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // CPU & Memory Indicators
            HStack(spacing: 16) {
                // CPU Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(process.formattedCPU)
                        .font(.title3)
                        .bold()
                        .foregroundColor(process.cpuPercent > 10.0 ? .purple : .primary)
                    Text("CPU Kullanımı")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                // RAM Badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text(process.formattedMemory)
                        .font(.title3)
                        .bold()
                        .foregroundColor(process.memoryMB >= 1024 ? .red : .primary)
                    Text("RAM Tüketimi")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.trailing, 8)

            // Action Button
            Button(action: onKill) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                    Text("Kill")
                }
                .font(.subheadline)
                .bold()
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .help("Süreci sonlandır (kill -9)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(isHovered ? Color(NSColor.controlBackgroundColor) : Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(10)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
