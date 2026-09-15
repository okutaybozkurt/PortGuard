import SwiftUI

public struct DashboardProcessRow: View {
    public let process: PortProcess
    public let onKill: () -> Void
    @Binding var isSelected: Bool
    @AppStorage("appLanguage") private var appLanguage: String = "tr"

    @State private var isHovered = false
    @State private var showInfoPopover = false

    public init(process: PortProcess, isSelected: Binding<Bool> = .constant(false), onKill: @escaping () -> Void) {
        self.process = process
        self._isSelected = isSelected
        self.onKill = onKill
    }

    public var body: some View {
        HStack(spacing: 16) {
            // Checkbox for selection
            Button(action: {
                isSelected.toggle()
            }) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .blue : AppleTheme.secondaryLabel.opacity(0.5))
            }
            .buttonStyle(.plain)
            .padding(.leading, 4)

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
                            .help("Geliştirici servisi".localized(language: appLanguage))
                    }
                    Text(process.processName)
                        .font(.system(size: 14, weight: .semibold))
                        .tracking(-0.1)
                        .foregroundColor(AppleTheme.label)

                    if let info = ProcessInfoHelper.getInfo(for: process.processName, languageCode: appLanguage) {
                        Button(action: {
                            showInfoPopover.toggle()
                        }) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.blue.opacity(0.85))
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $showInfoPopover, arrowEdge: .top) {
                            Text(info)
                                .font(.system(size: 12))
                                .padding(12)
                                .frame(width: 240)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                HStack(spacing: 6) {
                    Text(verbatim: "PID \(process.pid) · \(process.user)")
                        .font(.system(size: 11))
                        .foregroundColor(AppleTheme.secondaryLabel)

                    Text(process.formattedUptime)
                        .appleBadgeStyle(color: process.isLongRunning ? .red : AppleTheme.secondaryLabel)
                        .help(process.isLongRunning ? "Uzun süredir açık — unutulmuş olabilir".localized(language: appLanguage) : "Ne zamandır dinliyor".localized(language: appLanguage))

                    // Özellik 7: Docker container badge
                    if let containerName = process.dockerContainerName {
                        HStack(spacing: 4) {
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 9))
                            Text(containerName)
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .appleBadgeStyle(color: .cyan)
                        .help("Docker container: \(containerName)")
                    }
                }
            }

            Spacer()

            // Resource Metrics (CPU, RAM, Bandwidth)
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

                // Özellik 3: Bandwidth
                if process.hasNetworkActivity {
                    VStack(alignment: .trailing, spacing: 2) {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(process.formattedNetworkOut)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.teal)
                            Text(process.formattedNetworkIn)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.indigo)
                        }
                        Text("NET")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(0.4)
                            .foregroundColor(AppleTheme.secondaryLabel)
                    }
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
                .help("\(process.processName) (\(process.port)) " + "Süreci Durdur".localized(language: appLanguage))
            } else {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppleTheme.secondaryLabel)
                    .help("Bu, birden fazla port/container'a hizmet eden paylaşılan bir sistem süreci — sonlandırılamaz.".localized(language: appLanguage))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .appleCardStyle(hovered: isHovered)
        .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
        .cornerRadius(12)
        .onHover { hovering in
            withAnimation(.appleSpring) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            isSelected.toggle()
        }
    }
}
