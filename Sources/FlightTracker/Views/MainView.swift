// MainView.swift – Main window with sidebar navigation

import SwiftUI

struct MainView: View {
    @ObservedObject var dataStore = DataStore.shared
    @ObservedObject var scheduler = CheckScheduler.shared

    @State private var selectedRouteID: UUID?
    @State private var showAddRoute = false
    @State private var showSettings = false
    @State private var showAlerts = false
    @State private var showStopConfirm = false
    @State private var searchText = ""

    private var filteredRoutes: [TrackedRoute] {
        let routes = dataStore.trackedRoutes
        if searchText.isEmpty { return routes }
        return routes.filter {
            $0.route.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.airline.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let id = selectedRouteID,
               let route = dataStore.trackedRoutes.first(where: { $0.id == id }) {
                RouteDetailView(trackedRoute: route)
            } else {
                welcomeView
            }
        }
        .navigationTitle("Flight Tracker")
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showAddRoute) {
            AddRouteView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showAlerts) {
            AlertsHistoryView()
        }
        .alert("Hentikan Monitoring?", isPresented: $showStopConfirm) {
            Button("Batal", role: .cancel) {}
            Button("Hentikan", role: .destructive) {
                stopAllAndQuit()
            }
        } message: {
            Text("Semua proses monitoring akan dihentikan dan aplikasi akan ditutup. Yakin?")
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedRouteID) {
            Section {
                DashboardSidebarCell()
                    .tag(UUID())
            } header: {
                Text("Overview")
            }

            Section {
                ForEach(filteredRoutes) { route in
                    RouteSidebarCell(tracked: route)
                        .tag(route.id)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                dataStore.deleteTrackedRoute(id: route.id)
                            } label: {
                                Label("Hapus", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button(action: { scheduler.runManualCheck() }) {
                                Label("Cek Sekarang", systemImage: "arrow.clockwise")
                            }
                            Button(role: .destructive, action: { dataStore.deleteTrackedRoute(id: route.id) }) {
                                Label("Hapus Rute", systemImage: "trash")
                            }
                        }
                }
            } header: {
                HStack {
                    Text("Rute Dipantau (\(dataStore.trackedRoutes.count))")
                    Spacer()
                    Button(action: { showAddRoute = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !scheduler.recentNotifications.isEmpty {
                Section("Notifikasi Terbaru") {
                    ForEach(scheduler.recentNotifications.prefix(5)) { alert in
                        AlertSidebarCell(alert: alert)
                    }
                    if scheduler.recentNotifications.count > 5 {
                        Button("Lihat semua \(scheduler.recentNotifications.count)...") {
                            showAlerts = true
                        }
                        .font(.caption)
                        .foregroundStyle(.blue)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .searchable(text: $searchText, prompt: "Cari rute...")
        .frame(minWidth: 240, maxWidth: 280)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showAddRoute = true }) {
                    Label("Tambah Rute", systemImage: "plus")
                }
                .help("Tambah rute baru untuk dipantau")
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .automatic) {
            // Check status
            if scheduler.isRunning {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("Aktif")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Activity
            if !scheduler.currentActivity.isEmpty {
                Text(scheduler.currentActivity)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 200)
            }

            // Manual check button
            Button(action: { scheduler.runManualCheck() }) {
                Label("Cek Sekarang", systemImage: "arrow.clockwise.circle.fill")
            }
            .help("Cek harga sekarang untuk semua rute aktif")
            .disabled(!scheduler.isRunning && dataStore.trackedRoutes.isEmpty)

            // Start/Stop toggle
            Button(action: {
                if scheduler.isRunning { scheduler.stop() }
                else { scheduler.start() }
            }) {
                Label(
                    scheduler.isRunning ? "Stop Monitoring" : "Start Monitoring",
                    systemImage: scheduler.isRunning ? "stop.circle.fill" : "play.circle.fill"
                )
            }
            .help(scheduler.isRunning ? "Stop pemantauan otomatis" : "Mulai pemantauan otomatis")
            .tint(scheduler.isRunning ? .red : .green)

            // Alerts
            Button(action: { showAlerts = true }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                    if !scheduler.recentNotifications.isEmpty {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .help("Lihat notifikasi harga")

            // Settings
            Button(action: { showSettings = true }) {
                Image(systemName: "gear")
            }
            .help("Pengaturan")

            Divider()

            // Stop & Quit
            Button(action: {
                if scheduler.isRunning {
                    showStopConfirm = true
                } else {
                    NSApp.terminate(nil)
                }
            }) {
                Label(
                    scheduler.isRunning ? "Hentikan & Keluar" : "Keluar",
                    systemImage: scheduler.isRunning ? "stop.circle" : "power")
            }
            .help(scheduler.isRunning ? "Hentikan semua monitoring dan tutup aplikasi" : "Tutup aplikasi")
            .tint(.red)
        }
    }

    // MARK: - Stop & Quit

    private func stopAllAndQuit() {
        scheduler.stop()
        scheduler.currentActivity = "Monitoring dihentikan."
        NSApp.terminate(nil)
    }

    // MARK: - Welcome View

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Image(systemName: "airplane.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)
                .symbolEffect(.pulse)

            VStack(spacing: 8) {
                Text("Flight Price Tracker")
                    .font(.largeTitle)
                    .fontWeight(.black)
                Text("Pantau harga tiket pesawat dan dapatkan notifikasi\nketika harga mencapai titik terendah")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 16) {
                Button(action: { showAddRoute = true }) {
                    Label("Tambah Rute", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: { scheduler.start() }) {
                    Label("Mulai Monitoring", systemImage: "play.circle.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(dataStore.trackedRoutes.isEmpty)
            }

            // Feature highlights
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                FeatureCard(icon: "bell.badge.fill", color: .orange,
                    title: "Notifikasi Harga", desc: "Notifikasi otomatis saat harga mencapai titik terendah baru")
                FeatureCard(icon: "chart.line.downtrend.xyaxis", color: .blue,
                    title: "Analisis Tren", desc: "Lihat grafik perubahan harga dari waktu ke waktu")
                FeatureCard(icon: "clock.badge.checkmark", color: .green,
                    title: "Pola Waktu", desc: "Temukan jam dan hari terbaik untuk harga termurah")
                FeatureCard(icon: "airplane.arrival", color: .purple,
                    title: "Multi Maskapai", desc: "Pantau semua maskapai sekaligus untuk rute yang sama")
                FeatureCard(icon: "menubar.rectangle", color: .indigo,
                    title: "Menu Bar Widget", desc: "Akses cepat harga terbaru dari menu bar macOS")
                FeatureCard(icon: "square.and.arrow.up", color: .teal,
                    title: "Export CSV", desc: "Export data harga untuk analisis lebih lanjut")
            }
            .frame(maxWidth: 700)
        }
        .padding(40)
    }
}

// MARK: - Sidebar Cells

struct RouteSidebarCell: View {
    let tracked: TrackedRoute
    @ObservedObject var dataStore = DataStore.shared

    private var lowestEver: Double? {
        dataStore.allTimeLow(
            for: tracked.route.id,
            airline: tracked.airline,
            cabin: tracked.cabinClass
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(tracked.route.origin.iataCode)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(tracked.route.destination.iataCode)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Circle()
                    .fill(tracked.isActive ? Color.green : Color.gray)
                    .frame(width: 6, height: 6)
            }

            HStack(spacing: 4) {
                Text(tracked.airline == "ALL" ? "Semua" : tracked.airline)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(tracked.cabinClass.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let low = lowestEver {
                Text(formatIDR(low))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }

    private func formatIDR(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency
        f.locale = Locale(identifier: "id_ID"); f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "Rp\(Int(v))"
    }
}

struct DashboardSidebarCell: View {
    @ObservedObject var scheduler = CheckScheduler.shared

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                .foregroundStyle(.blue)
            Text("Dashboard")
                .font(.subheadline)
        }
    }
}

struct AlertSidebarCell: View {
    let alert: CheckScheduler.PriceAlert

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bell.fill")
                .foregroundStyle(.yellow)
                .font(.caption)
            VStack(alignment: .leading, spacing: 1) {
                Text(alert.routeKey)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text(alert.priceFormatted)
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let color: Color
    let title: String
    let desc: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(desc)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(color.opacity(0.15), lineWidth: 1)
        )
    }
}
