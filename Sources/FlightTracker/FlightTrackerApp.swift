// FlightTrackerApp.swift – App entry point

import SwiftUI
import UserNotifications

@main
struct FlightTrackerApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            FlightTrackerCommands()
        }
    }
}

// MARK: - App Delegate

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {

    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Request notification permission
        Task { @MainActor in
            _ = await CheckScheduler.shared.requestNotificationPermission()
        }

        // Setup menu bar widget
        Task { @MainActor in
            let controller = MenuBarController()
            controller.setup()
            menuBarController = controller
        }

        // Auto-start if routes exist
        Task { @MainActor in
            if !DataStore.shared.trackedRoutes.isEmpty {
                CheckScheduler.shared.start()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep running in menu bar after window closes
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Stop all background monitoring before quitting
        Task { @MainActor in
            CheckScheduler.shared.stop()
            CheckScheduler.shared.currentActivity = "Aplikasi ditutup."
        }
        return .terminateNow
    }

    // Show notification in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Bring window to front when notification is clicked
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
        }
        completionHandler()
    }
}

// MARK: - Menu Commands

struct FlightTrackerCommands: Commands {
    @ObservedObject var scheduler = CheckScheduler.shared

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Cek Harga Sekarang") {
                scheduler.runManualCheck()
            }
            .keyboardShortcut("r", modifiers: [.command])

            Divider()

            Button(scheduler.isRunning ? "Stop Monitoring" : "Start Monitoring") {
                if scheduler.isRunning { scheduler.stop() }
                else { scheduler.start() }
            }
            .keyboardShortcut("m", modifiers: [.command, .shift])

            Divider()

            Button("Hentikan Semua & Keluar") {
                CheckScheduler.shared.stop()
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command, .shift])
        }
    }
}
