// DataStore.swift – Persistence layer using JSON files in Application Support

import Foundation
import Combine

@MainActor
final class DataStore: ObservableObject {

    static let shared = DataStore()

    @Published private(set) var trackedRoutes: [TrackedRoute] = []
    @Published private(set) var priceHistory: [PriceRecord] = []
    @Published private(set) var checkSessions: [CheckSession] = []

    private let appSupportURL: URL
    private let trackedRoutesURL: URL
    private let priceHistoryURL: URL
    private let checkSessionsURL: URL

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        appSupportURL = base.appendingPathComponent("FlightTracker", isDirectory: true)

        trackedRoutesURL   = appSupportURL.appendingPathComponent("tracked_routes.json")
        priceHistoryURL    = appSupportURL.appendingPathComponent("price_history.json")
        checkSessionsURL   = appSupportURL.appendingPathComponent("check_sessions.json")

        try? fm.createDirectory(at: appSupportURL, withIntermediateDirectories: true)

        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        loadAll()
    }

    // MARK: - Load

    private func loadAll() {
        trackedRoutes  = load(from: trackedRoutesURL, as: [TrackedRoute].self) ?? []
        priceHistory   = load(from: priceHistoryURL,  as: [PriceRecord].self)  ?? []
        checkSessions  = load(from: checkSessionsURL, as: [CheckSession].self) ?? []
    }

    private func load<T: Decodable>(from url: URL, as type: T.Type) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    // MARK: - Save

    private func save<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Tracked Routes CRUD

    func addTrackedRoute(_ route: TrackedRoute) {
        trackedRoutes.append(route)
        save(trackedRoutes, to: trackedRoutesURL)
    }

    func updateTrackedRoute(_ updated: TrackedRoute) {
        if let idx = trackedRoutes.firstIndex(where: { $0.id == updated.id }) {
            trackedRoutes[idx] = updated
            save(trackedRoutes, to: trackedRoutesURL)
        }
    }

    func deleteTrackedRoute(id: UUID) {
        trackedRoutes.removeAll { $0.id == id }
        save(trackedRoutes, to: trackedRoutesURL)
    }

    func markRouteChecked(_ id: UUID, lowestPrice: Double?) {
        if let idx = trackedRoutes.firstIndex(where: { $0.id == id }) {
            trackedRoutes[idx].lastCheckedAt = Date()
            if let price = lowestPrice {
                if trackedRoutes[idx].lastLowestPrice == nil ||
                   price < trackedRoutes[idx].lastLowestPrice! {
                    trackedRoutes[idx].lastLowestPrice = price
                }
            }
            save(trackedRoutes, to: trackedRoutesURL)
        }
    }

    // MARK: - Price History

    func addPriceRecords(_ records: [PriceRecord]) {
        priceHistory.append(contentsOf: records)
        // Keep last 10,000 records to avoid unbounded growth
        if priceHistory.count > 10_000 {
            priceHistory = Array(priceHistory.suffix(10_000))
        }
        save(priceHistory, to: priceHistoryURL)
    }

    func priceHistory(for routeKey: String, airline: String, cabin: FlightOffer.CabinClass) -> [PriceRecord] {
        priceHistory.filter {
            $0.routeKey == routeKey &&
            ($0.airline == airline || airline == "ALL") &&
            $0.cabinClass == cabin
        }.sorted { $0.checkedAt < $1.checkedAt }
    }

    func allTimeLow(for routeKey: String, airline: String, cabin: FlightOffer.CabinClass) -> Double? {
        let history = priceHistory(for: routeKey, airline: airline, cabin: cabin)
        return history.map(\.price).min()
    }

    // MARK: - Check Sessions

    func addCheckSession(_ session: CheckSession) {
        checkSessions.insert(session, at: 0)
        if checkSessions.count > 500 {
            checkSessions = Array(checkSessions.prefix(500))
        }
        save(checkSessions, to: checkSessionsURL)
    }

    // MARK: - Pattern Analysis

    func computePattern(for routeKey: String, airline: String, cabin: FlightOffer.CabinClass) -> PricePattern? {
        let records = priceHistory(for: routeKey, airline: airline, cabin: cabin)
        guard records.count >= 3 else { return nil }

        // Group by hour
        var hourPrices: [Int: [Double]] = [:]
        var weekdayPrices: [Int: [Double]] = [:]

        for r in records {
            hourPrices[r.departureHour, default: []].append(r.price)
            weekdayPrices[r.departureWeekday, default: []].append(r.price)
        }

        let avgByHour = hourPrices.mapValues { $0.reduce(0, +) / Double($0.count) }
        let avgByWeekday = weekdayPrices.mapValues { $0.reduce(0, +) / Double($0.count) }

        let bestHour = avgByHour.min(by: { $0.value < $1.value })?.key ?? 0
        let bestWeekday = avgByWeekday.min(by: { $0.value < $1.value })?.key ?? 1

        return PricePattern(
            routeKey: routeKey,
            airline: airline,
            cabinClass: cabin,
            bestHour: bestHour,
            bestWeekday: bestWeekday,
            avgPriceByHour: avgByHour,
            avgPriceByWeekday: avgByWeekday,
            lowestEver: records.map(\.price).min() ?? 0,
            highestEver: records.map(\.price).max() ?? 0,
            sampleCount: records.count
        )
    }

    // MARK: - Export CSV

    func exportCSV(for routeKey: String) -> String {
        let records = priceHistory.filter { $0.routeKey == routeKey }
            .sorted { $0.checkedAt < $1.checkedAt }

        var csv = "CheckedAt,Route,Airline,Flight,DepartureDate,DepartureHour,Weekday,Price,Cabin,IsLowest\n"
        for r in records {
            let df = ISO8601DateFormatter()
            csv += "\(df.string(from: r.checkedAt)),\(r.routeKey),\(r.airline),\(r.flightNumber),\(df.string(from: r.departureDate)),\(r.departureHour),\(r.departureWeekday),\(Int(r.price)),\(r.cabinClass.rawValue),\(r.isLowest)\n"
        }
        return csv
    }

    // MARK: - Clear data

    func clearHistory(for routeKey: String) {
        priceHistory.removeAll { $0.routeKey == routeKey }
        save(priceHistory, to: priceHistoryURL)
    }
}
