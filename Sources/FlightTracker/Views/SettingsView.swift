// SettingsView.swift – Pengaturan aplikasi

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var scheduler = CheckScheduler.shared

    // ── Data source ──
    @State private var useDemoMode: Bool  = UserDefaults.standard.bool(forKey: "use_demo_mode")

    // ── Interval ──
    @State private var checkInterval: Int = {
        let v = UserDefaults.standard.integer(forKey: "check_interval_minutes")
        return v > 0 ? v : 60
    }()

    // ── Date range ──
    @State private var dateRangeMode: DateRangeMode = {
        let raw = UserDefaults.standard.string(forKey: "date_range_mode") ?? ""
        return DateRangeMode(rawValue: raw) ?? .daysAhead
    }()
    @State private var daysAhead: Int = {
        let v = UserDefaults.standard.integer(forKey: "days_ahead")
        return v > 0 ? v : 7
    }()
    @State private var rangeStart: Date = {
        let ts = UserDefaults.standard.double(forKey: "range_start_date")
        return ts > 0 ? Date(timeIntervalSince1970: ts) : Calendar.current.startOfDay(for: Date())
    }()
    @State private var rangeEnd: Date = {
        let ts = UserDefaults.standard.double(forKey: "range_end_date")
        if ts > 0 { return Date(timeIntervalSince1970: ts) }
        // Default: akhir bulan depan
        let cal = Calendar.current
        let now = Date()
        let nextMonth = cal.date(byAdding: .month, value: 1, to: now)!
        let comps = cal.dateComponents([.year, .month], from: nextMonth)
        let firstOfNext = cal.date(from: comps)!
        return cal.date(byAdding: .day, value: -1, to:
            cal.date(byAdding: .month, value: 1, to: firstOfNext)!)!
    }()

    // ── Notifications ──
    @State private var notificationGranted = false
    @State private var testNotifSent = false

    // ── UI state ──
    @State private var saved = false
    @State private var showRangeError = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    dataSourceSection
                    dateRangeSection
                    intervalSection
                    notificationSection
                    technicalSection
                }
                .padding()
            }

            Divider()
            footerBar
        }
        .frame(width: 480, height: 600)
        .task {
            notificationGranted = await scheduler.requestNotificationPermission()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("Pengaturan")
                .font(.headline).fontWeight(.bold)
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary).font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Data Source

    private var dataSourceSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "globe.asia.australia.fill")
                        .font(.title2).foregroundStyle(.blue).frame(width: 32)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Google Flights (real-time)")
                            .font(.subheadline).fontWeight(.semibold)
                        Text("Harga diambil langsung dari Google Penerbangan. Tidak memerlukan API key.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Divider()
                Toggle(isOn: $useDemoMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mode Demo")
                            .font(.subheadline)
                        Text("Data simulasi — untuk testing tanpa koneksi internet")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                if useDemoMode {
                    Label("Mode demo aktif — bukan harga nyata", systemImage: "info.circle")
                        .font(.caption2).foregroundStyle(.orange)
                }
            }
        } label: {
            Label("Sumber Data", systemImage: "antenna.radiowaves.left.and.right")
                .font(.subheadline).fontWeight(.semibold)
        }
    }

    // MARK: - Date Range Section

    private var dateRangeSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 14) {

                // Mode picker
                Picker("Mode pengecekan tanggal", selection: $dateRangeMode) {
                    ForEach(DateRangeMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Divider()

                // Mode: N hari ke depan
                if dateRangeMode == .daysAhead {
                    daysAheadRow
                }

                // Mode: Rentang tetap
                if dateRangeMode == .fixedRange {
                    fixedRangeRows
                }

                // Preview
                previewRow
            }
        } label: {
            Label("Tanggal yang Dicek", systemImage: "calendar")
                .font(.subheadline).fontWeight(.semibold)
        }
    }

    private var daysAheadRow: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Jumlah hari ke depan")
                    .font(.subheadline)
                Text("Dihitung dari hari ini")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                // Quick-pick buttons
                ForEach([7, 14, 30], id: \.self) { n in
                    Button("\(n)") {
                        daysAhead = n
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(daysAhead == n ? .blue : .secondary)
                }
                Stepper("", value: $daysAhead, in: 1...90)
                    .labelsHidden()
                Text("\(daysAhead) hari")
                    .font(.subheadline).monospacedDigit()
                    .frame(width: 64, alignment: .trailing)
            }
        }
    }

    private var fixedRangeRows: some View {
        VStack(spacing: 10) {
            // Start date
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tanggal mulai")
                        .font(.subheadline)
                    Text("Hari pertama yang dicek")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                DatePicker("", selection: $rangeStart, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .onChange(of: rangeStart) { _, newVal in
                        // Auto-geser end jika start melewati end
                        if newVal > rangeEnd { rangeEnd = newVal }
                        showRangeError = false
                    }
            }

            // End date
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tanggal selesai")
                        .font(.subheadline)
                    Text("Hari terakhir yang dicek")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                DatePicker("", selection: $rangeEnd,
                           in: rangeStart...,
                           displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .onChange(of: rangeEnd) { _, _ in showRangeError = false }
            }

            // Quick-select shortcuts
            VStack(alignment: .leading, spacing: 6) {
                Text("Pintasan cepat:")
                    .font(.caption2).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickRangePresets, id: \.label) { preset in
                            Button(preset.label) {
                                rangeStart = preset.start
                                rangeEnd   = preset.end
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(isActivePreset(preset) ? .blue : .secondary)
                        }
                    }
                }
            }

            if showRangeError {
                Label("Tanggal selesai harus setelah tanggal mulai", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2).foregroundStyle(.red)
            }
        }
    }

    private var previewRow: some View {
        let dates = previewDates
        let count = dates.count

        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "calendar.badge.checkmark")
                .foregroundStyle(.green).font(.subheadline)
            VStack(alignment: .leading, spacing: 4) {
                Text("**\(count) tanggal** yang akan dicek:")
                    .font(.caption)
                if count > 0 {
                    Text(previewText(dates))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        }
        .padding(10)
        .background(.green.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Check Interval

    private var intervalSection: some View {
        GroupBox {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Interval pengecekan otomatis")
                        .font(.subheadline)
                    Text("Seberapa sering harga dicek ulang secara otomatis")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer()
                Picker("", selection: $checkInterval) {
                    Text("15 menit").tag(15)
                    Text("30 menit").tag(30)
                    Text("1 jam").tag(60)
                    Text("2 jam").tag(120)
                    Text("4 jam").tag(240)
                    Text("8 jam").tag(480)
                    Text("24 jam").tag(1440)
                }
                .frame(width: 120)
            }
        } label: {
            Label("Monitoring Otomatis", systemImage: "timer")
                .font(.subheadline).fontWeight(.semibold)
        }
    }

    // MARK: - Notifications

    private var notificationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {

                // Baris status + tombol test
                HStack(alignment: .top, spacing: 10) {
                    // Ikon status
                    Image(systemName: "bell.badge.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 6) {
                        // Penjelasan cara kerja
                        Text("Notifikasi dikirim otomatis via **AppleScript** — tidak memerlukan izin tambahan dari System Settings.")
                            .font(.caption)

                        // Tombol Test
                        HStack(spacing: 8) {
                            Button {
                                scheduler.sendTestNotification()
                                testNotifSent = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    testNotifSent = false
                                }
                            } label: {
                                Label(testNotifSent ? "Terkirim!" : "Kirim Test Notifikasi",
                                      systemImage: testNotifSent ? "checkmark.circle.fill" : "bell.and.waves.left.and.right")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .tint(testNotifSent ? .green : .orange)
                            .disabled(testNotifSent)

                            if testNotifSent {
                                Text("Cek sudut kanan atas layar")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Divider()

                // Panduan aktifkan di System Settings jika tidak muncul
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 8) {
                        notifStep(num: "1", text: "Klik tombol \"Kirim Test Notifikasi\" di atas")
                        notifStep(num: "2", text: "Jika tidak muncul, buka: **System Settings → Notifications**")
                        notifStep(num: "3", text: "Cari **\"Script Editor\"** dalam daftar (notifikasi osascript berjalan di bawah Script Editor)")
                        notifStep(num: "4", text: "Pastikan **\"Allow Notifications\"** aktif dan style-nya **Alerts** atau **Banners**")
                        notifStep(num: "5", text: "Klik test lagi — notifikasi seharusnya muncul di sudut kanan atas")

                        Divider()

                        Button {
                            NSWorkspace.shared.open(
                                URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
                            )
                        } label: {
                            Label("Buka System Settings → Notifications", systemImage: "arrow.up.right.square")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.top, 4)
                } label: {
                    Label("Cara mengaktifkan notifikasi", systemImage: "questionmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } label: {
            Label("Notifikasi", systemImage: "bell.badge.fill")
                .font(.subheadline).fontWeight(.semibold)
        }
    }

    private func notifStep(num: String, text: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(num)
                .font(.caption2).fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(.blue))
            Text(text)
                .font(.caption2)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Technical

    private var technicalSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Label("Lokasi scraper.py", systemImage: "doc.text")
                    .font(.caption2).foregroundStyle(.secondary)
                Text(scraperPath)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        } label: {
            Label("Info Teknis", systemImage: "gearshape.2")
                .font(.subheadline).fontWeight(.semibold)
        }
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack {
            Button("Batal") { dismiss() }
                .keyboardShortcut(.escape)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            Spacer()
            if saved {
                Label("Tersimpan!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green).font(.subheadline)
                    .transition(.opacity)
            }
            Button(action: saveSettings) {
                Label("Simpan", systemImage: "checkmark")
            }
            .keyboardShortcut(.return)
            .buttonStyle(.borderedProminent)
            .disabled(dateRangeMode == .fixedRange && rangeStart > rangeEnd)
        }
        .padding()
        .background(.bar)
        .animation(.easeInOut(duration: 0.3), value: saved)
    }

    // MARK: - Helpers

    private var scraperPath: String {
        let path = "\(NSHomeDirectory())/FlightTracker/scraper.py"
        return FileManager.default.fileExists(atPath: path)
            ? "✅ \(path)" : "❌ \(path) (tidak ditemukan)"
    }

    // Daftar pintasan cepat rentang tanggal
    struct RangePreset {
        let label: String
        let start: Date
        let end: Date
    }

    private var quickRangePresets: [RangePreset] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        func monthRange(offset: Int) -> (Date, Date) {
            let target = cal.date(byAdding: .month, value: offset, to: today)!
            var comps = cal.dateComponents([.year, .month], from: target)
            let first = cal.date(from: comps)!
            comps.month! += 1
            let last = cal.date(byAdding: .day, value: -1, to: cal.date(from: comps)!)!
            return (first, last)
        }

        let df = DateFormatter()
        df.dateFormat = "MMM yyyy"
        df.locale = Locale(identifier: "id_ID")

        let (m0s, m0e) = monthRange(offset: 0)
        let (m1s, m1e) = monthRange(offset: 1)
        let (m2s, m2e) = monthRange(offset: 2)
        let (m3s, m3e) = monthRange(offset: 3)

        let nextWeekEnd  = cal.date(byAdding: .day, value: 6, to: today)!
        let next2WeekEnd = cal.date(byAdding: .day, value: 13, to: today)!
        let next30End    = cal.date(byAdding: .day, value: 29, to: today)!

        return [
            RangePreset(label: "7 hari",  start: today, end: nextWeekEnd),
            RangePreset(label: "14 hari", start: today, end: next2WeekEnd),
            RangePreset(label: "30 hari", start: today, end: next30End),
            RangePreset(label: df.string(from: m0s), start: m0s, end: m0e),
            RangePreset(label: df.string(from: m1s), start: m1s, end: m1e),
            RangePreset(label: df.string(from: m2s), start: m2s, end: m2e),
            RangePreset(label: df.string(from: m3s), start: m3s, end: m3e),
        ]
    }

    private func isActivePreset(_ preset: RangePreset) -> Bool {
        let cal = Calendar.current
        return cal.isDate(preset.start, inSameDayAs: rangeStart) &&
               cal.isDate(preset.end,   inSameDayAs: rangeEnd)
    }

    // Tanggal yang akan dicek berdasarkan state saat ini
    private var previewDates: [Date] {
        let cal = Calendar.current
        switch dateRangeMode {
        case .daysAhead:
            let today = cal.startOfDay(for: Date())
            return (0..<daysAhead).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
        case .fixedRange:
            guard rangeStart <= rangeEnd else { return [] }
            var dates: [Date] = []
            var cur = cal.startOfDay(for: rangeStart)
            let last = cal.startOfDay(for: rangeEnd)
            while cur <= last {
                dates.append(cur)
                cur = cal.date(byAdding: .day, value: 1, to: cur)!
            }
            return dates
        }
    }

    private func previewText(_ dates: [Date]) -> String {
        guard !dates.isEmpty else { return "-" }
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        df.locale = Locale(identifier: "id_ID")
        if dates.count <= 6 {
            return dates.map { df.string(from: $0) }.joined(separator: ", ")
        } else {
            // Tampilkan beberapa awal + akhir
            let first3 = dates.prefix(3).map { df.string(from: $0) }.joined(separator: ", ")
            let last1  = df.string(from: dates.last!)
            return "\(first3) … \(last1)"
        }
    }

    // MARK: - Save

    private func saveSettings() {
        guard !(dateRangeMode == .fixedRange && rangeStart > rangeEnd) else {
            showRangeError = true
            return
        }

        let ud = UserDefaults.standard
        ud.set(useDemoMode,            forKey: "use_demo_mode")
        ud.set(checkInterval,          forKey: "check_interval_minutes")
        ud.set(dateRangeMode.rawValue, forKey: "date_range_mode")
        ud.set(daysAhead,              forKey: "days_ahead")
        ud.set(rangeStart.timeIntervalSince1970, forKey: "range_start_date")
        ud.set(rangeEnd.timeIntervalSince1970,   forKey: "range_end_date")

        scheduler.checkIntervalMinutes = checkInterval
        scheduler.reloadConfig()

        saved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            saved = false
            dismiss()
        }
    }
}
