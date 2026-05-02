// FlightScraper.swift
// Two scraper implementations:
//   1. GoogleFlightsScraper  – Real prices via Google Flights (headless Playwright, no API key needed)
//   2. DemoFlightScraper     – Simulation with realistic price patterns (offline fallback)
//
// The app uses GoogleFlightsScraper by default.
// DemoFlightScraper is used automatically when scraper.py is not found or network fails.

import Foundation

// MARK: - Protocol

protocol FlightScraperProtocol {
    func fetchOffers(
        origin: String,
        destination: String,
        date: Date,
        airline: String,         // IATA code or "ALL"
        cabin: FlightOffer.CabinClass
    ) async throws -> [FlightOffer]
}

// MARK: - Error

enum ScraperError: LocalizedError {
    case networkError(String)
    case parseError(String)
    case noResults
    case scriptNotFound

    var errorDescription: String? {
        switch self {
        case .networkError(let m): return "Network error: \(m)"
        case .parseError(let m):   return "Parse error: \(m)"
        case .noResults:           return "No flights found for this route/date."
        case .scriptNotFound:      return "scraper.py not found. Using demo mode."
        }
    }
}

// MARK: - Demo Scraper (fallback / offline)

/// Generates realistic Indonesian flight prices with real market patterns:
/// - Prices vary by airline, hour of day, day of week
/// - Prices fluctuate ±12% each check to simulate real market movement
final class DemoFlightScraper: FlightScraperProtocol {

    private let basePrices: [String: Double] = [
        "CGK-DPS": 1_400_000, "DPS-CGK": 1_400_000,
        "CGK-SUB": 850_000,   "SUB-CGK": 850_000,
        "CGK-UPG": 1_300_000, "UPG-CGK": 1_300_000,
        "CGK-KNO": 1_050_000, "KNO-CGK": 1_050_000,
        "CGK-BPN": 1_200_000, "BPN-CGK": 1_200_000,
        "CGK-JOG": 600_000,   "JOG-CGK": 600_000,
        "CGK-SOC": 650_000,   "SOC-CGK": 650_000,
        "CGK-PLM": 700_000,   "PLM-CGK": 700_000,
        "CGK-PDG": 800_000,   "PDG-CGK": 800_000,
        "CGK-SIN": 1_600_000, "SIN-CGK": 1_600_000,
        "CGK-KUL": 1_300_000, "KUL-CGK": 1_300_000,
        "SUB-DPS": 450_000,   "DPS-SUB": 450_000,
    ]

    private let airlineMult: [String: Double] = [
        "GA": 1.40, "QG": 1.10, "ID": 1.15,
        "JT": 0.88, "QZ": 0.87, "SJ": 0.92,
        "IW": 0.82, "TN": 0.85, "IN": 0.83,
        "SQ": 2.30, "MH": 1.55, "EK": 3.60, "QR": 3.20,
    ]

    private let hourMult: [Int: Double] = [
        0: 0.91, 1: 0.89, 2: 0.88, 3: 0.88, 4: 0.90, 5: 0.93,
        6: 0.96, 7: 1.06, 8: 1.11, 9: 1.13, 10: 1.09, 11: 1.06,
        12: 1.11, 13: 1.09, 14: 1.07, 15: 1.11, 16: 1.13, 17: 1.16,
        18: 1.19, 19: 1.16, 20: 1.06, 21: 0.99, 22: 0.93, 23: 0.91,
    ]

    // 1=Sun cheapest=Tue(3), most expensive=Fri(6)/Sat(7)
    private let weekdayMult: [Int: Double] = [
        1: 1.14, 2: 0.96, 3: 0.91, 4: 0.94, 5: 1.06, 6: 1.22, 7: 1.19
    ]

    func fetchOffers(origin: String, destination: String, date: Date,
                     airline: String, cabin: FlightOffer.CabinClass) async throws -> [FlightOffer] {
        try await Task.sleep(nanoseconds: 400_000_000)

        let routeKey = "\(origin)-\(destination)"
        let base = basePrices[routeKey] ?? 1_200_000
        let cabinMult: Double = cabin == .economy ? 1.0 : cabin == .business ? 3.6 : 7.2

        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date)
        let wMult = weekdayMult[weekday] ?? 1.0

        let targetAirlines: [String] = airline == "ALL"
            ? Array(["GA", "JT", "QG", "QZ", "ID", "TN"].shuffled().prefix(5))
            : [airline]

        var offers: [FlightOffer] = []

        for code in targetAirlines {
            let aMult = airlineMult[code] ?? 1.0
            let hours = [5, 6, 7, 9, 11, 13, 15, 17, 19, 21].shuffled().prefix(Int.random(in: 3...5))

            for hour in hours {
                let hMult = hourMult[hour] ?? 1.0
                let fluct = Double.random(in: 0.88...1.12)
                let price = (base * cabinMult * aMult * hMult * wMult * fluct / 1000).rounded() * 1000

                var depComps = cal.dateComponents([.year, .month, .day], from: date)
                depComps.hour = hour
                depComps.minute = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45].randomElement()!
                let depDate = cal.date(from: depComps) ?? date
                let durMin = ["CGK","DPS","SUB","UPG","KNO","BPN","JOG","SOC","PLM","PDG"].contains(destination)
                    ? Int.random(in: 60...210) : Int.random(in: 180...720)
                let arrDate = depDate.addingTimeInterval(Double(durMin * 60))

                let name = Airline.popular.first { $0.iataCode == code }?.name ?? code

                offers.append(FlightOffer(
                    airline: code, airlineName: name,
                    flightNumber: "\(code)\(Int.random(in: 100...999))",
                    origin: origin, destination: destination,
                    departureDate: depDate, arrivalDate: arrDate,
                    price: price, cabinClass: cabin,
                    seatsAvailable: Int.random(in: 1...9),
                    checkedBaggage: cabin == .economy ? (["JT","QZ","TN"].contains(code) ? 0 : 20) : 30,
                    fetchedAt: Date()
                ))
            }
        }
        return offers.sorted { $0.price < $1.price }
    }
}

// MARK: - Scraper config

struct ScraperConfig {
    var useDemoMode: Bool

    // Tanggal pengecekan
    var dateRangeMode: DateRangeMode
    var daysAhead: Int           // dipakai saat mode = .daysAhead
    var rangeStartDate: Date?    // dipakai saat mode = .fixedRange
    var rangeEndDate: Date?      // dipakai saat mode = .fixedRange

    // Kembalikan array tanggal yang perlu dicek berdasarkan mode
    func datesToCheck() -> [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        switch dateRangeMode {
        case .daysAhead:
            return (0..<daysAhead).compactMap {
                cal.date(byAdding: .day, value: $0, to: today)
            }

        case .fixedRange:
            guard let start = rangeStartDate, let end = rangeEndDate, start <= end else {
                // Fallback ke daysAhead jika range belum di-set
                return (0..<daysAhead).compactMap {
                    cal.date(byAdding: .day, value: $0, to: today)
                }
            }
            var dates: [Date] = []
            var current = cal.startOfDay(for: start)
            let last    = cal.startOfDay(for: end)
            while current <= last {
                dates.append(current)
                current = cal.date(byAdding: .day, value: 1, to: current)!
            }
            return dates
        }
    }

    // Label ringkas untuk ditampilkan di UI
    var rangeLabel: String {
        switch dateRangeMode {
        case .daysAhead:
            return "\(daysAhead) hari ke depan"
        case .fixedRange:
            guard let s = rangeStartDate, let e = rangeEndDate else { return "Rentang belum diatur" }
            let df = DateFormatter()
            df.dateFormat = "d MMM yyyy"
            df.locale = Locale(identifier: "id_ID")
            let days = Calendar.current.dateComponents([.day], from:
                Calendar.current.startOfDay(for: s),
                to: Calendar.current.startOfDay(for: e)).day! + 1
            return "\(df.string(from: s)) – \(df.string(from: e)) (\(days) hari)"
        }
    }

    static func load() -> ScraperConfig {
        let ud = UserDefaults.standard
        let demo = ud.bool(forKey: "use_demo_mode")
        let modeRaw = ud.string(forKey: "date_range_mode") ?? DateRangeMode.daysAhead.rawValue
        let mode = DateRangeMode(rawValue: modeRaw) ?? .daysAhead
        let days = ud.integer(forKey: "days_ahead").clamped(to: 1...90)
        let startTS = ud.double(forKey: "range_start_date")
        let endTS   = ud.double(forKey: "range_end_date")
        let start: Date? = startTS > 0 ? Date(timeIntervalSince1970: startTS) : nil
        let end:   Date? = endTS   > 0 ? Date(timeIntervalSince1970: endTS)   : nil
        return ScraperConfig(
            useDemoMode: demo,
            dateRangeMode: mode,
            daysAhead: days > 0 ? days : 7,
            rangeStartDate: start,
            rangeEndDate: end
        )
    }

    func save() {
        let ud = UserDefaults.standard
        ud.set(useDemoMode, forKey: "use_demo_mode")
        ud.set(dateRangeMode.rawValue, forKey: "date_range_mode")
        ud.set(daysAhead, forKey: "days_ahead")
        if let s = rangeStartDate { ud.set(s.timeIntervalSince1970, forKey: "range_start_date") }
        if let e = rangeEndDate   { ud.set(e.timeIntervalSince1970, forKey: "range_end_date")   }
    }
}

// MARK: - Clamp helper

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        max(range.lowerBound, min(self, range.upperBound))
    }
}

// MARK: - Convenience

extension Array {
    var empty: Bool { isEmpty }
}
