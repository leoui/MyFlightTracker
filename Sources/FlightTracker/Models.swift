// Models.swift – Core data models for FlightTracker

import Foundation

// MARK: - Airport

struct Airport: Codable, Hashable, Identifiable {
    var id: String { iataCode }
    let iataCode: String   // e.g. "CGK"
    let name: String
    let city: String
    let country: String

    static let popular: [Airport] = [
        Airport(iataCode: "CGK", name: "Soekarno-Hatta International", city: "Jakarta", country: "Indonesia"),
        Airport(iataCode: "SUB", name: "Juanda International", city: "Surabaya", country: "Indonesia"),
        Airport(iataCode: "DPS", name: "Ngurah Rai International", city: "Bali", country: "Indonesia"),
        Airport(iataCode: "UPG", name: "Sultan Hasanuddin International", city: "Makassar", country: "Indonesia"),
        Airport(iataCode: "MDC", name: "Sam Ratulangi International", city: "Manado", country: "Indonesia"),
        Airport(iataCode: "BPN", name: "Sultan Aji Muhammad Sulaiman", city: "Balikpapan", country: "Indonesia"),
        Airport(iataCode: "PLM", name: "Sultan Mahmud Badaruddin II", city: "Palembang", country: "Indonesia"),
        Airport(iataCode: "PDG", name: "Minangkabau International", city: "Padang", country: "Indonesia"),
        Airport(iataCode: "KNO", name: "Kualanamu International", city: "Medan", country: "Indonesia"),
        Airport(iataCode: "JOG", name: "Adisutjipto International", city: "Yogyakarta", country: "Indonesia"),
        Airport(iataCode: "SOC", name: "Adisumarmo International", city: "Solo", country: "Indonesia"),
        Airport(iataCode: "SIN", name: "Changi International", city: "Singapore", country: "Singapore"),
        Airport(iataCode: "KUL", name: "Kuala Lumpur International", city: "Kuala Lumpur", country: "Malaysia"),
        Airport(iataCode: "BKK", name: "Suvarnabhumi International", city: "Bangkok", country: "Thailand"),
        Airport(iataCode: "HKG", name: "Hong Kong International", city: "Hong Kong", country: "Hong Kong"),
        Airport(iataCode: "SYD", name: "Kingsford Smith International", city: "Sydney", country: "Australia"),
        Airport(iataCode: "DOH", name: "Hamad International", city: "Doha", country: "Qatar"),
        Airport(iataCode: "DXB", name: "Dubai International", city: "Dubai", country: "UAE"),
    ]
}

// MARK: - Airline

struct Airline: Codable, Hashable, Identifiable {
    var id: String { iataCode }
    let iataCode: String
    let name: String
    let logoSymbol: String  // SF Symbol fallback

    static let popular: [Airline] = [
        Airline(iataCode: "GA", name: "Garuda Indonesia", logoSymbol: "airplane"),
        Airline(iataCode: "JT", name: "Lion Air", logoSymbol: "airplane"),
        Airline(iataCode: "SJ", name: "Sriwijaya Air", logoSymbol: "airplane"),
        Airline(iataCode: "ID", name: "Batik Air", logoSymbol: "airplane"),
        Airline(iataCode: "IW", name: "Wings Air", logoSymbol: "airplane"),
        Airline(iataCode: "IN", name: "Nam Air", logoSymbol: "airplane"),
        Airline(iataCode: "QZ", name: "AirAsia Indonesia", logoSymbol: "airplane"),
        Airline(iataCode: "XT", name: "Indonesia AirAsia X", logoSymbol: "airplane"),
        Airline(iataCode: "SQ", name: "Singapore Airlines", logoSymbol: "airplane"),
        Airline(iataCode: "MH", name: "Malaysia Airlines", logoSymbol: "airplane"),
        Airline(iataCode: "EK", name: "Emirates", logoSymbol: "airplane"),
        Airline(iataCode: "QR", name: "Qatar Airways", logoSymbol: "airplane"),
        Airline(iataCode: "CX", name: "Cathay Pacific", logoSymbol: "airplane"),
        Airline(iataCode: "TG", name: "Thai Airways", logoSymbol: "airplane"),
        Airline(iataCode: "ALL", name: "All Airlines", logoSymbol: "airplane.circle"),
    ]
}

// MARK: - Route

struct Route: Codable, Hashable, Identifiable {
    var id: String { "\(origin.iataCode)-\(destination.iataCode)" }
    let origin: Airport
    let destination: Airport

    var displayName: String {
        "\(origin.city) (\(origin.iataCode)) → \(destination.city) (\(destination.iataCode))"
    }
}

// MARK: - Flight Offer (one check result)

struct FlightOffer: Codable, Identifiable {
    var id = UUID()
    let airline: String          // IATA code e.g. "GA"
    let airlineName: String
    let flightNumber: String
    let origin: String           // IATA
    let destination: String      // IATA
    let departureDate: Date
    let arrivalDate: Date
    let price: Double            // in IDR
    let cabinClass: CabinClass
    let seatsAvailable: Int
    let checkedBaggage: Int      // kg, 0 = not included
    let fetchedAt: Date

    var departureHour: Int { Calendar.current.component(.hour, from: departureDate) }
    var departureWeekday: Int { Calendar.current.component(.weekday, from: departureDate) } // 1=Sun
    var departureWeekdayName: String { DateFormatter().weekdaySymbols[departureWeekday - 1] }
    var durationMinutes: Int { Int(arrivalDate.timeIntervalSince(departureDate) / 60) }

    enum CabinClass: String, Codable, CaseIterable {
        case economy = "Economy"
        case business = "Business"
        case first = "First"
    }
}

// MARK: - Price Record (historical)

struct PriceRecord: Codable, Identifiable {
    var id = UUID()
    let routeKey: String           // "CGK-DPS"
    let airline: String            // IATA or "ALL"
    let cabinClass: FlightOffer.CabinClass
    let departureDate: Date        // actual flight date
    let price: Double
    let flightNumber: String
    let departureHour: Int         // 0-23
    let departureWeekday: Int      // 1-7 (Sun-Sat)
    let checkedAt: Date
    let isLowest: Bool             // true if lowest ever seen for this route/airline/cabin

    // Mark whether this was lowest at time of recording
    var priceFormatted: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "id_ID")
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: price)) ?? "Rp \(Int(price))"
    }
}

// MARK: - Price Pattern (analytics)

struct PricePattern: Identifiable {
    var id = UUID()
    let routeKey: String
    let airline: String
    let cabinClass: FlightOffer.CabinClass

    // Best hour/day patterns
    let bestHour: Int              // 0-23 with lowest avg price
    let bestWeekday: Int           // 1-7
    let avgPriceByHour: [Int: Double]    // hour -> avg price
    let avgPriceByWeekday: [Int: Double] // weekday -> avg price
    let lowestEver: Double
    let highestEver: Double
    let sampleCount: Int
}

// MARK: - Tracked Route (user config)

struct TrackedRoute: Codable, Identifiable {
    var id = UUID()
    let route: Route
    let airline: String            // IATA or "ALL" for all airlines
    let cabinClass: FlightOffer.CabinClass
    var isActive: Bool
    var alertThreshold: Double?    // notify if price drops below this (nil = new all-time low)
    var createdAt: Date
    var lastCheckedAt: Date?
    var lastLowestPrice: Double?   // last known lowest for this route/airline/cabin
}

// MARK: - Check Session

struct CheckSession: Codable, Identifiable {
    var id = UUID()
    let routeKey: String
    let airline: String
    let cabinClass: FlightOffer.CabinClass
    let checkedAt: Date
    let offersFound: [FlightOffer]
    let lowestInSession: Double?
    let isNewAllTimeLow: Bool
}

// MARK: - Date Range Config

/// Mode pengecekan tanggal keberangkatan
enum DateRangeMode: String, Codable, CaseIterable {
    case daysAhead   = "days_ahead"    // N hari dari hari ini
    case fixedRange  = "fixed_range"   // Rentang tanggal tetap (misal 1–30 Juni)

    var displayName: String {
        switch self {
        case .daysAhead:  return "N Hari ke Depan"
        case .fixedRange: return "Rentang Tanggal Tertentu"
        }
    }
}

// MARK: - Weekday helpers

extension Int {
    var weekdayShortName: String {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        guard self >= 1 && self <= 7 else { return "?" }
        return names[self - 1]
    }
}
