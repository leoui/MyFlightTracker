// AutoUpdater.swift – Update app via .dmg file browse
// 1. User selects .dmg file
// 2. Mount DMG → find .app inside
// 3. Replace current running app with new .app
// 4. Restart app automatically

import Foundation
import AppKit

@MainActor
final class AutoUpdater: ObservableObject {
    static let shared = AutoUpdater()

    @Published var isUpdating = false
    @Published var updateMessage = ""
    @Published var updateError: String?
    @Published var updateSuccess = false

    // Current running app path
    private var currentAppPath: String {
        Bundle.main.bundlePath
    }

    private var currentAppName: String {
        (currentAppPath as NSString).lastPathComponent
    }

    // Browse and apply update from DMG
    func browseAndUpdate() {
        let panel = NSOpenPanel()
        panel.title = "Pilih File .dmg untuk Update"
        panel.allowedContentTypes = [.diskImage]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.message = "Pilih file DMG MyFlightTracker yang sudah di-download dari GitHub Releases"

        guard panel.runModal() == .OK, let dmgURL = panel.url else { return }

        Task {
            await performUpdate(dmgURL: dmgURL)
        }
    }

    private func performUpdate(dmgURL: URL) async {
        isUpdating = true
        updateError = nil
        updateSuccess = false
        updateMessage = "📦 Mounting DMG..."

        let dmgPath = dmgURL.path
        let mountPoint = "/tmp/MyFlightTracker_Update_\(ProcessInfo.processInfo.processIdentifier)"
        let fileManager = FileManager.default

        // 1. Mount DMG
        let mountResult = await shell(
            "/usr/bin/hdiutil",
            args: ["attach", dmgPath, "-mountpoint", mountPoint, "-nobrowse", "-quiet", "-noverify"]
        )
        guard mountResult.exitCode == 0 else {
            fail("Gagal mount DMG: \(mountResult.stderr)")
            return
        }
        defer {
            // Always unmount when done
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                await shell("/usr/bin/hdiutil", args: ["detach", mountPoint, "-force"])
            }
        }

        // 2. Find .app inside mounted DMG
        updateMessage = "🔍 Mencari aplikasi di dalam DMG..."

        let findResult = await shell(
            "/usr/bin/find",
            args: [mountPoint, "-maxdepth", "2", "-name", "*.app", "-type", "d"]
        )

        let apps = findResult.stdout.split(separator: "\n").map(String.init).filter { !$0.isEmpty }
        guard let newAppPath = apps.first else {
            fail("Tidak ditemukan .app di dalam DMG. Pastikan DMG berisi MyFlightTracker.app")
            return
        }

        let newAppName = (newAppPath as NSString).lastPathComponent
        updateMessage = "✅ Ditemukan: \(newAppName)"

        // 3. Verify it's a valid macOS app (has Info.plist)
        let infoPlistPath = "\(newAppPath)/Contents/Info.plist"
        guard fileManager.fileExists(atPath: infoPlistPath) else {
            fail("File .app tidak valid (Info.plist tidak ditemukan)")
            return
        }

        // 4. Copy new app to replace current app
        updateMessage = "🔄 Mengganti aplikasi..."

        // Get the parent directory of current app
        let currentDir = (currentAppPath as NSString).deletingLastPathComponent
        let destinationPath = "\(currentDir)/\(currentAppName)"

        // Remove existing app (except if it's the running app — we'll handle that below)
        if destinationPath != currentAppPath {
            // App is running from different location than where we're installing
            do {
                if fileManager.fileExists(atPath: destinationPath) {
                    try fileManager.removeItem(atPath: destinationPath)
                }
                try fileManager.copyItem(atPath: newAppPath, toPath: destinationPath)
            } catch {
                fail("Gagal menyalin aplikasi: \(error.localizedDescription)")
                return
            }
        } else {
            // App is running from the target location — use rsync to replace in-place
            // rsync can replace files even if some are in use (they stay in memory until restart)
            let rsyncResult = await shell(
                "/usr/bin/rsync",
                args: ["-a", "--delete", "--force", "\(newAppPath)/", "\(destinationPath)/"]
            )
            guard rsyncResult.exitCode == 0 else {
                fail("Gagal mengganti aplikasi: \(rsyncResult.stderr)")
                return
            }
        }

        updateMessage = "✅ Update berhasil! Restart dalam 2 detik..."
        updateSuccess = true

        // 5. Remove quarantine attribute
        await shell("/usr/bin/xattr", args: ["-cr", destinationPath])

        // 6. Re-sign if ad-hoc (to ensure it runs)
        await shell("/usr/bin/codesign", args: ["--force", "--deep", "--sign", "-", destinationPath])

        // 7. Restart app after brief delay
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // Launch new instance
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-n", destinationPath]
        try? process.run()

        // Terminate current instance
        try? await Task.sleep(nanoseconds: 500_000_000)
        NSApp.terminate(nil)
    }

    private func fail(_ message: String) {
        updateError = message
        updateMessage = ""
        isUpdating = false
    }

    // MARK: - Shell helper

    private func shell(_ path: String, args: [String]) async -> (stdout: String, stderr: String, exitCode: Int32) {
        await withCheckedContinuation { cont in
            DispatchQueue.global(qos: .userInitiated).async {
                let proc = Process()
                proc.executableURL = URL(fileURLWithPath: path)
                proc.arguments = args

                let out = Pipe()
                let err = Pipe()
                proc.standardOutput = out
                proc.standardError  = err

                try? proc.run()
                proc.waitUntilExit()

                let outStr = String(data: out.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let errStr = String(data: err.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

                cont.resume(returning: (outStr, errStr, proc.terminationStatus))
            }
        }
    }
}
