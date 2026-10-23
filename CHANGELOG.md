# Changelog

🇬🇧 **English** · 🇹🇷 [Türkçe](CHANGELOG.tr.md)

All notable changes to this project will be documented in this file.

## [1.0.4] - 2026-10-23

### Added
- **Port conflict resolver:** One-click "Stop and Restart" for a busy port. The command and working directory are shown in a confirmation dialog; arguments are launched without being re-interpreted by a shell, and the process is re-verified right before it is stopped (protection against PID reuse).
- **Process details panel:** Working directory, full command line, PID/PPID, and start time, with "Show in Finder" and copy actions.
- **Quick search palette (⌥⌘P):** Search by port or process name, stop with a second confirmation (↩), or restart with ⌘↩. Can be turned off in Settings.

### Changed
- Redesigned popover: Port / RAM / CPU cards and rows with an inline RAM bar.
- The menu bar icon stays the PortGuard shield; a small alert dot appears on its corner when a rule is violated.
- macOS-native touches: ⌘R refresh, ⌘F search, ⌘D dashboard, ⌘, settings; fixed-width digits, system selection color, accessibility labels, and a consistent translucent popover background.

### Fixed
- The kill (✕) button in the dashboard did not show a confirmation dialog because two SwiftUI `.alert` modifiers on the same view conflicted. Confirmation now uses `NSAlert`, and the ✕ in the menu bar popover asks for confirmation too.

### Performance
- While the window and popover are not visible, refreshes drop to once every 20 seconds and the `nettop` / connection scan is skipped. History is written at most once a minute, and timer tolerance lets the system coalesce wake-ups.

### Known limitations
- Restart only works for processes owned by the same user and does not reproduce the original shell environment (for example, a process started with `npm run dev` is restarted as `node ...`).

## [1.0.3] - 2026-09-15

### Added
- **Network Activity:** Live list of ESTABLISHED and other TCP connections per process (PID, local port, remote address/port, state), with explanations of TCP states and real per-process inbound/outbound bandwidth computed from `nettop` sample deltas.
- **History & trends:** Daily archive of system snapshots (`~/.portguard/history/YYYY-MM-DD.json`) with average/peak RAM, average CPU, and active port count.
- **Rule engine:** Threshold-based rules (RAM, CPU, uptime) with automatic notification or kill actions, full create/edit/enable/delete UI, and live violation tracking.
- **Project scanner:** Scans `package.json`, `.env`, `docker-compose.yml`, `Makefile`, `Dockerfile` and similar files for ports and warns about conflicts with running processes.

### Changed
- Bandwidth is now measured as the delta between two `nettop` samples (`nettop -l 2`) for accurate bytes per second.
- The "Check for Updates" button is bound to reactive state and links directly to the latest release.
- All new screens and messages are fully localized in Turkish and English.
- Docker: LISTEN ports and container names are matched correctly, and `ps` / `lsof` output filtering is more robust.

## [1.0.2] - 2026-08-04

### Added
- **Multi-select and batch kill:** Tick several processes in the dashboard and stop them at once with "Stop Selected".
- **Process info popover:** An (i) icon next to well-known services (node, electron, python, docker, dart, …) explains what they do.
- **Live language switching (Turkish/English):** A language picker in Settings that applies instantly, without restarting the app.
- **Update checker:** A new `UpdateManager` checks the GitHub API for the latest release and links to the installer.
- **Developer link:** The developer name in Settings now opens the personal website (orhankutaybozkurt.com).
- **Release automation:** A `bump_version.sh` script updates version and build numbers.

### Changed
- The version number is read dynamically from `Info.plist` instead of being hard-coded.
- README updated with the new features and security policy.
- Process termination now uses `kill -15` (SIGTERM) instead of `kill -9` (SIGKILL), which is safer and more stable.

## [1.0.1]

### Fixed
- Docker Desktop's shared system processes (`com.docker.backend`, `com.docker.vmnetd`, `com.docker.supervisor`) could be killed from the dashboard, taking down networking for every container. They are now on a protected list: still visible, but the kill button becomes a lock icon, with a second independent guard inside `PortMonitorEngine.killProcess()`.
- Correct detection of Docker-published ports (full, untruncated process names).
- Switched from `kill -9` to `kill -15` so processes can shut down gracefully.

## [1.0.0]

- Initial release: live port, PID, RAM and CPU tracking, one-click process kill, high-memory notifications, a developer-services filter with a custom whitelist, and 100% local operation with zero telemetry.
