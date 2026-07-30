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
        HStack(spacing: 8) {
            // Port Badge
            Text(":\(process.port)")
                .font(.system(.caption, design: .monospaced))
                .bold()
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.15))
                .foregroundColor(.blue)
                .cornerRadius(4)

            // Process Info
            VStack(alignment: .leading, spacing: 2) {
                Text(process.processName)
                    .font(.caption)
                    .bold()
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text("PID: \(process.pid)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    if process.cpuPercent > 0.1 {
                        Text("• \(process.formattedCPU)")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
            }

            Spacer()

            // RAM Badge
            Text(process.formattedMemory)
                .font(.caption2)
                .bold()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(process.memoryMB >= 1024 ? Color.red.opacity(0.15) : Color.orange.opacity(0.12))
                .foregroundColor(process.memoryMB >= 1024 ? .red : .orange)
                .cornerRadius(4)

            // Kill Button
            Button(action: onKill) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help("\(process.processName) (\(process.port)) sürecini sonlandır")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHovered ? Color.primary.opacity(0.05) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
