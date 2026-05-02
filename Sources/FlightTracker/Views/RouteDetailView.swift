// RouteDetailView.swift – Detail view for a single tracked route

import SwiftUI

struct RouteDetailView: View {
    let trackedRoute: TrackedRoute
    @ObservedObject var dataStore = DataStore.shared
    @ObservedObject var scheduler = CheckScheduler.shared

    @State private var selectedTab = 0

    private var records: [PriceRecord] {
        dataStore.priceHistory(
            for: trackedRoute.route.id,
            airline: trackedRoute.airline,
            cabin: trackedRoute.cabinClass
        )
    }

    private var pattern: PricePattern? {
        dataStore.computePattern(
            for: trackedRoute.route.id,
            airline: trackedRoute.airline,
            cabin: trackedRoute.cabinClass
        )
    }

    private var allTimeLow: Double? {
        dataStore.allTimeLow(
            for: trackedRoute.route.id,
            airline: trackedRoute.airline,
            cabin: trackedRoute.cabinClass
        )
    }

    private var latestOffers: [FlightOffer] {
        scheduler.latestOffers.filter {
            "\($0.origin)-\($0.destination)" == trackedRoute.route.id
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Hero header
            routeHeader

            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Penawaran").tag(0)
                Text("Riwayat").tag(1)
                Text("Pola").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)

            Divider()

            // Content
            switch selectedTab {
            case 0: offersTab
            case 1: historyTab
            case 2: patternTab
            default: EmptyView()
            }
        }
    }

    // MARK: - Header

    private var routeHeader: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading) {
                    Text(trackedRoute.route.origin.iataCode)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                    Text(trackedRoute.route.origin.city)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 2) {
                    Image(systemName: "airplane")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    Rectangle()
                        .fill(.blue.opacity(0.3))
                        .frame(height: 1)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .trailing) {
                    Text(trackedRoute.route.destination.iataCode)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                    Text(trackedRoute.route.destination.city)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            HStack(spacing: 16) {
                Label(airlineName, systemImage: "airplane.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(trackedRoute.cabinClass.rawValue, systemImage: "seat.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let low = allTimeLow {
                    Label(formatIDR(low), systemImage: "tag.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }

            if let lastCheck = trackedRoute.lastCheckedAt {
                Text("Terakhir dicek: \(lastCheck.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.08), Color.clear],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - Offers Tab

    private var offersTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if latestOffers.isEmpty {
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "Belum Ada Data",
                            systemImage: "airplane.arrival",
                            description: Text("Klik 'Cek Sekarang' untuk mengambil harga terbaru")
                        )
                        Button(action: {
                            CheckScheduler.shared.runManualCheck()
                        }) {
                            Label("Cek Sekarang", systemImage: "arrow.clockwise.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 40)
                } else {
                    // Best deal banner
                    if let best = latestOffers.first {
                        BestDealBanner(offer: best, allTimeLow: allTimeLow)
                            .padding(.horizontal)
                    }

                    // All offers grouped by date
                    let grouped = Dictionary(grouping: latestOffers) {
                        Calendar.current.startOfDay(for: $0.departureDate)
                    }
                    ForEach(grouped.keys.sorted(), id: \.self) { date in
                        if let dayOffers = grouped[date] {
                            Section {
                                ForEach(dayOffers) { offer in
                                    FlightOfferRow(
                                        offer: offer,
                                        isLowest: offer.price == latestOffers.map(\.price).min(),
                                        allTimeLow: allTimeLow
                                    )
                                }
                            } header: {
                                Text(date.formatted(.dateTime.weekday(.wide).day().month()))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - History Tab

    private var historyTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PriceHistoryChartView(records: records, routeKey: trackedRoute.route.id)

                if !records.isEmpty {
                    // Stats grid
                    statsGrid

                    // History table
                    historyTable
                }
            }
            .padding()
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            StatCard(title: "Terendah", value: formatIDR(records.map(\.price).min() ?? 0), color: .green)
            StatCard(title: "Tertinggi", value: formatIDR(records.map(\.price).max() ?? 0), color: .red)
            StatCard(title: "Rata-rata", value: formatIDR(records.map(\.price).reduce(0,+) / Double(records.count)), color: .blue)
            StatCard(title: "Total Cek", value: "\(records.count)", color: .purple)
        }
    }

    private var historyTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Riwayat Detail")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.bottom, 8)

            // Header
            HStack {
                Text("Dicek").font(.caption2).foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
                Text("Maskapai").font(.caption2).foregroundStyle(.secondary).frame(width: 80, alignment: .leading)
                Text("Penerbangan").font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                Text("Jam").font(.caption2).foregroundStyle(.secondary).frame(width: 40, alignment: .center)
                Text("Hari").font(.caption2).foregroundStyle(.secondary).frame(width: 40, alignment: .center)
                Text("Harga").font(.caption2).foregroundStyle(.secondary).frame(width: 90, alignment: .trailing)
                Text("").frame(width: 16)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(Color.secondary.opacity(0.1))

            ForEach(records.reversed().prefix(100)) { record in
                HStack {
                    Text(record.checkedAt.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 80, alignment: .leading)
                    Text(record.airline)
                        .font(.caption2)
                        .frame(width: 80, alignment: .leading)
                    Text(record.flightNumber)
                        .font(.caption2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(String(format: "%02d:xx", record.departureHour))
                        .font(.caption2)
                        .frame(width: 40, alignment: .center)
                    Text(record.departureWeekday.weekdayShortName)
                        .font(.caption2)
                        .frame(width: 40, alignment: .center)
                    Text(formatIDR(record.price))
                        .font(.caption2)
                        .fontWeight(record.isLowest ? .bold : .regular)
                        .foregroundStyle(record.isLowest ? .green : .primary)
                        .frame(width: 90, alignment: .trailing)
                    Image(systemName: record.isLowest ? "star.fill" : "")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                        .frame(width: 16)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(record.isLowest ? Color.green.opacity(0.06) : Color.clear)
                Divider()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Pattern Tab

    private var patternTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let pattern = pattern {
                    PricePatternView(pattern: pattern)
                    Divider()
                    ExportButton(routeKey: trackedRoute.route.id)
                } else {
                    ContentUnavailableView(
                        "Data Tidak Cukup",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Butuh minimal 3 pemeriksaan harga untuk melihat pola.\nMulai monitoring dan biarkan sistem bekerja.")
                    )
                    .padding(.top, 40)
                }
            }
            .padding()
        }
    }

    // MARK: - Helpers

    private var airlineName: String {
        if trackedRoute.airline == "ALL" { return "Semua Maskapai" }
        return Airline.popular.first(where: { $0.iataCode == trackedRoute.airline })?.name
            ?? trackedRoute.airline
    }

    private func formatIDR(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "id_ID")
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "Rp\(Int(value))"
    }
}

// MARK: - Best Deal Banner

struct BestDealBanner: View {
    let offer: FlightOffer
    let allTimeLow: Double?

    private var isNewLow: Bool {
        guard let low = allTimeLow else { return false }
        return offer.price <= low
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if isNewLow {
                    Label("Harga Terendah Sepanjang Masa!", systemImage: "trophy.fill")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                } else {
                    Label("Penawaran Terbaik Saat Ini", systemImage: "star.fill")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatIDR(offer.price))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(isNewLow ? .green : .primary)
                Text("/ orang")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label(offer.airlineName, systemImage: "airplane")
                    .font(.caption)
                Label(offer.flightNumber, systemImage: "number")
                    .font(.caption)
                Label(offer.departureDate.formatted(.dateTime.hour().minute()), systemImage: "clock")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isNewLow
                ? LinearGradient(colors: [Color.green.opacity(0.15), Color.green.opacity(0.05)], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [Color.orange.opacity(0.1), Color.orange.opacity(0.03)], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isNewLow ? Color.green.opacity(0.4) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private func formatIDR(_ value: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency
        f.locale = Locale(identifier: "id_ID"); f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "Rp\(Int(value))"
    }
}

// MARK: - Flight Offer Row

struct FlightOfferRow: View {
    let offer: FlightOffer
    let isLowest: Bool
    let allTimeLow: Double?

    private var isAllTimeLow: Bool {
        guard let low = allTimeLow else { return false }
        return offer.price <= low
    }

    var body: some View {
        HStack(spacing: 12) {
            // Airline badge
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(offer.airline)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
            }

            // Flight info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(offer.flightNumber)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if isAllTimeLow {
                        Label("Harga terendah!", systemImage: "trophy.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.yellow.opacity(0.15))
                            .clipShape(Capsule())
                    } else if isLowest {
                        Label("Termurah hari ini", systemImage: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 8) {
                    Text(offer.departureDate.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(offer.arrivalDate.formatted(.dateTime.hour().minute()))
                        .font(.caption)

                    Text("•").foregroundStyle(.tertiary)

                    Text("\(offer.durationMinutes / 60)j \(offer.durationMinutes % 60)m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    if offer.checkedBaggage > 0 {
                        Label("\(offer.checkedBaggage)kg", systemImage: "bag.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    } else {
                        Label("No baggage", systemImage: "bag")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    Label("\(offer.seatsAvailable) kursi", systemImage: "seat")
                        .font(.caption2)
                        .foregroundStyle(offer.seatsAvailable <= 3 ? .red : .secondary)
                }
            }

            Spacer()

            // Price
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatIDR(offer.price))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(isAllTimeLow ? .green : (isLowest ? .orange : .primary))
                Text(offer.cabinClass.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isAllTimeLow ? Color.green.opacity(0.05) : Color.clear)
    }

    private func formatIDR(_ value: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .currency
        f.locale = Locale(identifier: "id_ID"); f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "Rp\(Int(value))"
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Export Button

struct ExportButton: View {
    let routeKey: String
    @State private var exported = false

    var body: some View {
        Button(action: exportCSV) {
            Label(exported ? "Tersimpan!" : "Export CSV", systemImage: exported ? "checkmark" : "square.and.arrow.up")
        }
        .buttonStyle(.bordered)
    }

    private func exportCSV() {
        let csv = DataStore.shared.exportCSV(for: routeKey)
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "flight-prices-\(routeKey).csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        if panel.runModal() == .OK, let url = panel.url {
            try? csv.write(to: url, atomically: true, encoding: .utf8)
            exported = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { exported = false }
        }
    }
}
