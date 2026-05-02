// MenuBarWidget.swift – macOS menu bar status item with popover

import SwiftUI
import AppKit

// MARK: - Menu Bar Controller

@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "airplane.circle", accessibilityDescription: "Flight Tracker")
            button.image?.isTemplate = true
            button.toolTip = "Flight Price Tracker"
            button.action = #selector(togglePopover)
            button.target = self
        }

        let pop = NSPopover()
        pop.contentSize = NSSize(width: 360, height: 480)
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(rootView: MenuBarPopoverView())
        pop.animates = true
        self.popover = pop

        updateIcon()

        // Update icon when new notifications arrive
        NotificationCenter.default.addObserver(self,
            selector: #selector(updateIcon),
            name: NSNotification.Name("FlightPriceAlert"),
            object: nil)
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }
        if let pop = popover {
            if pop.isShown {
                pop.performClose(nil)
            } else {
                pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                pop.contentViewController?.view.window?.makeKey()
            }
        }
    }

    @objc private func updateIcon() {
        let hasAlerts = !CheckScheduler.shared.recentNotifications.isEmpty
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: hasAlerts ? "airplane.circle.fill" : "airplane.circle",
                accessibilityDescription: "Flight Tracker"
            )
            button.image?.isTemplate = !hasAlerts
        }
    }
}

// MARK: - Menu Bar Popover View

struct MenuBarPopoverView: View {
    @ObservedObject var dataStore = DataStore.shared
    @ObservedObject var scheduler = CheckScheduler.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            popoverHeader

            Divider()

            // Content
            ScrollView {
                VStack(spacing: 0) {
                    if dataStore.trackedRoutes.isEmpty {
                        emptyState
                    } else {
                        routeSummaries
                    }

                    if !scheduler.recentNotifications.isEmpty {
                        Divider()
                        recentAlerts
                    }
                }
            }

            Divider()
            popoverFooter
        }
        .frame(width: 360)
    }

    // MARK: - Header

    private var popoverHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "airplane.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 1) {
                Text("Flight Price Tracker")
                    .font(.subheadline)
                    .fontWeight(.bold)
                HStack(spacing: 4) {
                    Circle()
                        .fill(scheduler.isRunning ? Color.green : Color.orange)
                        .frame(width: 5, height: 5)
                    Text(scheduler.isRunning ? "Monitoring aktif" : "Monitoring tidak aktif")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    if let lastCheck = scheduler.lastCheckDate {
                        Text("· \(lastCheck.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Toggle monitoring
            Button(action: {
                if scheduler.isRunning { scheduler.stop() }
                else { scheduler.start() }
            }) {
                Image(systemName: scheduler.isRunning ? "stop.circle" : "play.circle")
                    .foregroundStyle(scheduler.isRunning ? .red : .green)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help(scheduler.isRunning ? "Stop monitoring" : "Start monitoring")
        }
        .padding(12)
    }

    // MARK: - Route Summaries

    private var routeSummaries: some View {
        VStack(spacing: 0) {
            ForEach(dataStore.trackedRoutes.prefix(8)) { tracked in
                MenuBarRouteRow(tracked: tracked)
                Divider()
                    .padding(.leading, 12)
            }
        }
    }

    // MARK: - Recent Alerts

    private var recentAlerts: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Notifikasi Terbaru", systemImage: "trophy.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            ForEach(scheduler.recentNotifications.prefix(3)) { alert in
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(alert.routeKey + " · " + alert.airline)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(alert.priceFormatted + " — " + alert.flightDate.formatted(.dateTime.day().month()))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(alert.alertDate.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 3)
            }

            if scheduler.recentNotifications.count > 3 {
                Text("+\(scheduler.recentNotifications.count - 3) lainnya...")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
            }
        }
        .padding(.bottom, 6)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle.dashed")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("Belum ada rute dipantau")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Buka aplikasi utama untuk\nmenambahkan rute penerbangan")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var popoverFooter: some View {
        HStack(spacing: 12) {
            Button(action: { scheduler.runManualCheck() }) {
                Label("Cek Sekarang", systemImage: "arrow.clockwise")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)

            Spacer()

            // Stop & Quit — prominent destructive action
            Button(action: stopAndQuit) {
                Label("Hentikan & Keluar", systemImage: "stop.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 16)

            Button(action: openMainWindow) {
                Label("Buka App", systemImage: "macwindow")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func stopAndQuit() {
        scheduler.stop()
        scheduler.currentActivity = "Monitoring dihentikan."
        NSApp.terminate(nil)
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Menu Bar Route Row

struct MenuBarRouteRow: View {
    let tracked: TrackedRoute
    @ObservedObject var dataStore = DataStore.shared
    @ObservedObject var scheduler = CheckScheduler.shared

    private var lowestEver: Double? {
        dataStore.allTimeLow(
            for: tracked.route.id,
            airline: tracked.airline,
            cabin: tracked.cabinClass
        )
    }

    private var latestPrice: Double? {
        scheduler.latestOffers
            .filter { "\($0.origin)-\($0.destination)" == tracked.route.id }
            .map(\.price)
            .min()
    }

    private var isNewLow: Bool {
        guard let latest = latestPrice, let low = lowestEver else { return false }
        return latest <= low
    }

    var body: some View {
        HStack(spacing: 10) {
            // Route
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(tracked.route.origin.iataCode)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                    Text(tracked.route.destination.iataCode)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)

                    if isNewLow {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.yellow)
                    }
                }

                Text((tracked.airline == "ALL" ? "Semua" : tracked.airline) + " · " + tracked.cabinClass.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Prices
            VStack(alignment: .trailing, spacing: 2) {
                if let latest = latestPrice {
                    Text(formatIDR(latest))
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(isNewLow ? .green : .primary)
                } else {
                    Text("—")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                if let low = lowestEver, let latest = latestPrice, latest > low {
                    Text("Min: " + formatIDR(low))
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isNewLow ? Color.green.opacity(0.05) : Color.clear)
    }

    private func formatIDR(_ v: Double) -> String {
        let millions = v / 1_000_000
        if millions >= 1 { return String(format: "Rp%.2fJt", millions) }
        return String(format: "Rp%.0fRb", v / 1_000)
    }
}
