// Models.swift – Core data models for FlightTracker

import Foundation

// MARK: - Airport

struct Airport: Codable, Hashable, Identifiable {
    var id: String { iataCode }
    let iataCode: String   // e.g. "CGK"
    let name: String
    let city: String
    let country: String

    var displayLabel: String {
        "\(city) (\(iataCode)) — \(name)"
    }

    // ---- SEMUA BANDARA DOMESTIK INDONESIA ----
    static let domestic: [Airport] = [
        // Jawa
        Airport(iataCode: "CGK", name: "Soekarno-Hatta International", city: "Jakarta", country: "Indonesia"),
        Airport(iataCode: "HLP", name: "Halim Perdanakusuma", city: "Jakarta", country: "Indonesia"),
        Airport(iataCode: "BDO", name: "Husein Sastranegara", city: "Bandung", country: "Indonesia"),
        Airport(iataCode: "KJT", name: "Kertajati International", city: "Majalengka", country: "Indonesia"),
        Airport(iataCode: "SRG", name: "Achmad Yani International", city: "Semarang", country: "Indonesia"),
        Airport(iataCode: "JOG", name: "Adisutjipto International", city: "Yogyakarta", country: "Indonesia"),
        Airport(iataCode: "YIA", name: "Yogyakarta International", city: "Yogyakarta", country: "Indonesia"),
        Airport(iataCode: "SOC", name: "Adisumarmo International", city: "Solo", country: "Indonesia"),
        Airport(iataCode: "SUB", name: "Juanda International", city: "Surabaya", country: "Indonesia"),
        Airport(iataCode: "MLG", name: "Abdul Rachman Saleh", city: "Malang", country: "Indonesia"),
        // Bali & Nusa Tenggara
        Airport(iataCode: "DPS", name: "Ngurah Rai International", city: "Bali", country: "Indonesia"),
        Airport(iataCode: "LOP", name: "Lombok International", city: "Lombok", country: "Indonesia"),
        Airport(iataCode: "BMU", name: "Sultan Muhammad Salahudin", city: "Bima", country: "Indonesia"),
        Airport(iataCode: "LBJ", name: "Komodo", city: "Labuan Bajo", country: "Indonesia"),
        Airport(iataCode: "TMC", name: "Tambolaka", city: "Sumba", country: "Indonesia"),
        Airport(iataCode: "KOE", name: "El Tari", city: "Kupang", country: "Indonesia"),
        // Sumatra
        Airport(iataCode: "KNO", name: "Kualanamu International", city: "Medan", country: "Indonesia"),
        Airport(iataCode: "BTJ", name: "Sultan Iskandar Muda", city: "Banda Aceh", country: "Indonesia"),
        Airport(iataCode: "PDG", name: "Minangkabau International", city: "Padang", country: "Indonesia"),
        Airport(iataCode: "PKU", name: "Sultan Syarif Kasim II", city: "Pekanbaru", country: "Indonesia"),
        Airport(iataCode: "PLM", name: "Sultan Mahmud Badaruddin II", city: "Palembang", country: "Indonesia"),
        Airport(iataCode: "BKS", name: "Fatmawati Soekarno", city: "Bengkulu", country: "Indonesia"),
        Airport(iataCode: "TKG", name: "Radin Inten II", city: "Bandar Lampung", country: "Indonesia"),
        Airport(iataCode: "PGK", name: "Depati Amir", city: "Pangkal Pinang", country: "Indonesia"),
        Airport(iataCode: "TNJ", name: "Raja Haji Fisabilillah", city: "Tanjung Pinang", country: "Indonesia"),
        Airport(iataCode: "BTH", name: "Hang Nadim International", city: "Batam", country: "Indonesia"),
        // Kalimantan
        Airport(iataCode: "BPN", name: "Sultan Aji Muhammad Sulaiman", city: "Balikpapan", country: "Indonesia"),
        Airport(iataCode: "BDJ", name: "Syamsudin Noor", city: "Banjarmasin", country: "Indonesia"),
        Airport(iataCode: "PNK", name: "Supadio International", city: "Pontianak", country: "Indonesia"),
        Airport(iataCode: "TRK", name: "Juwata International", city: "Tarakan", country: "Indonesia"),
        Airport(iataCode: "BEJ", name: "Kalimarau", city: "Berau", country: "Indonesia"),
        Airport(iataCode: "KTG", name: "Rahadi Oesman", city: "Ketapang", country: "Indonesia"),
        Airport(iataCode: "TJG", name: "Warukin", city: "Tanjung", country: "Indonesia"),
        Airport(iataCode: "AAP", name: "Aji Pangeran Tumenggung Pranoto", city: "Samarinda", country: "Indonesia"),
        // Sulawesi
        Airport(iataCode: "UPG", name: "Sultan Hasanuddin International", city: "Makassar", country: "Indonesia"),
        Airport(iataCode: "MDC", name: "Sam Ratulangi International", city: "Manado", country: "Indonesia"),
        Airport(iataCode: "KDI", name: "Haluoleo", city: "Kendari", country: "Indonesia"),
        Airport(iataCode: "GTO", name: "Jalaluddin", city: "Gorontalo", country: "Indonesia"),
        Airport(iataCode: "PLW", name: "Mutiara SIS Al-Jufrie", city: "Palu", country: "Indonesia"),
        Airport(iataCode: "LUW", name: "Bubung", city: "Luwuk", country: "Indonesia"),
        Airport(iataCode: "PSJ", name: "Kasiguncu", city: "Poso", country: "Indonesia"),
        Airport(iataCode: "BUW", name: "Baubau", city: "Buton", country: "Indonesia"),
        // Maluku & Papua
        Airport(iataCode: "AMQ", name: "Pattimura International", city: "Ambon", country: "Indonesia"),
        Airport(iataCode: "TTE", name: "Sultan Babullah", city: "Ternate", country: "Indonesia"),
        Airport(iataCode: "DJJ", name: "Sentani", city: "Jayapura", country: "Indonesia"),
        Airport(iataCode: "BIK", name: "Frans Kaisiepo", city: "Biak", country: "Indonesia"),
        Airport(iataCode: "SOQ", name: "Dominique Edward Osok", city: "Sorong", country: "Indonesia"),
        Airport(iataCode: "TIM", name: "Mozes Kilangin", city: "Timika", country: "Indonesia"),
        Airport(iataCode: "MKW", name: "Rendani", city: "Manokwari", country: "Indonesia"),
        Airport(iataCode: "NBX", name: "Nabire", city: "Nabire", country: "Indonesia"),
        Airport(iataCode: "WMX", name: "Wamena", city: "Wamena", country: "Indonesia"),
        Airport(iataCode: "MLN", name: "Mopah", city: "Merauke", country: "Indonesia"),
        Airport(iataCode: "KNG", name: "Kaimana", city: "Kaimana", country: "Indonesia"),
    ]

    // ---- BANDARA INTERNASIONAL POPULER ----
    static let international: [Airport] = [
        // Asia Tenggara
        Airport(iataCode: "SIN", name: "Changi International", city: "Singapore", country: "Singapore"),
        Airport(iataCode: "KUL", name: "Kuala Lumpur International", city: "Kuala Lumpur", country: "Malaysia"),
        Airport(iataCode: "BKK", name: "Suvarnabhumi International", city: "Bangkok", country: "Thailand"),
        Airport(iataCode: "DMK", name: "Don Mueang International", city: "Bangkok", country: "Thailand"),
        Airport(iataCode: "CNX", name: "Chiang Mai International", city: "Chiang Mai", country: "Thailand"),
        Airport(iataCode: "SGN", name: "Tan Son Nhat International", city: "Ho Chi Minh City", country: "Vietnam"),
        Airport(iataCode: "HAN", name: "Noi Bai International", city: "Hanoi", country: "Vietnam"),
        Airport(iataCode: "MNL", name: "Ninoy Aquino International", city: "Manila", country: "Philippines"),
        Airport(iataCode: "PNH", name: "Phnom Penh International", city: "Phnom Penh", country: "Cambodia"),
        Airport(iataCode: "REP", name: "Siem Reap International", city: "Siem Reap", country: "Cambodia"),
        Airport(iataCode: "RGN", name: "Yangon International", city: "Yangon", country: "Myanmar"),
        // Asia Timur
        Airport(iataCode: "HKG", name: "Hong Kong International", city: "Hong Kong", country: "Hong Kong"),
        Airport(iataCode: "TPE", name: "Taoyuan International", city: "Taipei", country: "Taiwan"),
        Airport(iataCode: "NRT", name: "Narita International", city: "Tokyo", country: "Japan"),
        Airport(iataCode: "HND", name: "Haneda", city: "Tokyo", country: "Japan"),
        Airport(iataCode: "KIX", name: "Kansai International", city: "Osaka", country: "Japan"),
        Airport(iataCode: "FUK", name: "Fukuoka", city: "Fukuoka", country: "Japan"),
        Airport(iataCode: "ICN", name: "Incheon International", city: "Seoul", country: "South Korea"),
        Airport(iataCode: "PVG", name: "Pudong International", city: "Shanghai", country: "China"),
        Airport(iataCode: "PEK", name: "Capital International", city: "Beijing", country: "China"),
        Airport(iataCode: "CAN", name: "Baiyun International", city: "Guangzhou", country: "China"),
        Airport(iataCode: "KMG", name: "Changshui International", city: "Kunming", country: "China"),
        // Asia Selatan & Tengah
        Airport(iataCode: "DEL", name: "Indira Gandhi International", city: "New Delhi", country: "India"),
        Airport(iataCode: "BOM", name: "Chhatrapati Shivaji International", city: "Mumbai", country: "India"),
        Airport(iataCode: "MLE", name: "Velana International", city: "Male", country: "Maldives"),
        // Timur Tengah
        Airport(iataCode: "DXB", name: "Dubai International", city: "Dubai", country: "UAE"),
        Airport(iataCode: "DWC", name: "Al Maktoum International", city: "Dubai", country: "UAE"),
        Airport(iataCode: "AUH", name: "Abu Dhabi International", city: "Abu Dhabi", country: "UAE"),
        Airport(iataCode: "DOH", name: "Hamad International", city: "Doha", country: "Qatar"),
        Airport(iataCode: "JED", name: "King Abdulaziz International", city: "Jeddah", country: "Saudi Arabia"),
        Airport(iataCode: "RUH", name: "King Khalid International", city: "Riyadh", country: "Saudi Arabia"),
        Airport(iataCode: "MED", name: "Prince Mohammad bin Abdulaziz", city: "Medinah", country: "Saudi Arabia"),
        Airport(iataCode: "IST", name: "Istanbul Airport", city: "Istanbul", country: "Turkey"),
        // Oceania
        Airport(iataCode: "SYD", name: "Kingsford Smith International", city: "Sydney", country: "Australia"),
        Airport(iataCode: "MEL", name: "Tullamarine", city: "Melbourne", country: "Australia"),
        Airport(iataCode: "PER", name: "Perth Airport", city: "Perth", country: "Australia"),
        Airport(iataCode: "AKL", name: "Auckland Airport", city: "Auckland", country: "New Zealand"),
        // Eropa
        Airport(iataCode: "LHR", name: "Heathrow", city: "London", country: "United Kingdom"),
        Airport(iataCode: "CDG", name: "Charles de Gaulle", city: "Paris", country: "France"),
        Airport(iataCode: "FRA", name: "Frankfurt Airport", city: "Frankfurt", country: "Germany"),
        Airport(iataCode: "AMS", name: "Schiphol", city: "Amsterdam", country: "Netherlands"),
        Airport(iataCode: "FCO", name: "Fiumicino", city: "Rome", country: "Italy"),
        Airport(iataCode: "MUC", name: "Franz Josef Strauss", city: "Munich", country: "Germany"),
    ]

    /// Semua bandara (domestik + internasional)
    static let all: [Airport] = domestic + international

    // Backward compat
    static let popular: [Airport] = all
}

// MARK: - Airline

struct Airline: Codable, Hashable, Identifiable {
    var id: String { iataCode }
    let iataCode: String
    let name: String
    let logoSymbol: String  // SF Symbol fallback

    static let popular: [Airline] = [
        // Indonesia
        Airline(iataCode: "GA", name: "Garuda Indonesia", logoSymbol: "airplane"),
        Airline(iataCode: "JT", name: "Lion Air", logoSymbol: "airplane"),
        Airline(iataCode: "SJ", name: "Sriwijaya Air", logoSymbol: "airplane"),
        Airline(iataCode: "ID", name: "Batik Air", logoSymbol: "airplane"),
        Airline(iataCode: "IW", name: "Wings Air", logoSymbol: "airplane"),
        Airline(iataCode: "IN", name: "Nam Air", logoSymbol: "airplane"),
        Airline(iataCode: "QZ", name: "AirAsia Indonesia", logoSymbol: "airplane"),
        Airline(iataCode: "XT", name: "Indonesia AirAsia X", logoSymbol: "airplane"),
        Airline(iataCode: "QG", name: "Citilink", logoSymbol: "airplane"),
        Airline(iataCode: "TN", name: "TransNusa", logoSymbol: "airplane"),
        Airline(iataCode: "MV", name: "Aviastar", logoSymbol: "airplane"),
        // Asia Tenggara
        Airline(iataCode: "SQ", name: "Singapore Airlines", logoSymbol: "airplane"),
        Airline(iataCode: "TR", name: "Scoot", logoSymbol: "airplane"),
        Airline(iataCode: "MH", name: "Malaysia Airlines", logoSymbol: "airplane"),
        Airline(iataCode: "AK", name: "AirAsia", logoSymbol: "airplane"),
        Airline(iataCode: "TG", name: "Thai Airways", logoSymbol: "airplane"),
        Airline(iataCode: "FD", name: "Thai AirAsia", logoSymbol: "airplane"),
        Airline(iataCode: "VN", name: "Vietnam Airlines", logoSymbol: "airplane"),
        Airline(iataCode: "PR", name: "Philippine Airlines", logoSymbol: "airplane"),
        Airline(iataCode: "CX", name: "Cathay Pacific", logoSymbol: "airplane"),
        Airline(iataCode: "BL", name: "Pacific Airlines", logoSymbol: "airplane"),
        // Asia Timur
        Airline(iataCode: "JL", name: "Japan Airlines", logoSymbol: "airplane"),
        Airline(iataCode: "NH", name: "ANA", logoSymbol: "airplane"),
        Airline(iataCode: "KE", name: "Korean Air", logoSymbol: "airplane"),
        Airline(iataCode: "OZ", name: "Asiana Airlines", logoSymbol: "airplane"),
        Airline(iataCode: "MU", name: "China Eastern", logoSymbol: "airplane"),
        Airline(iataCode: "CA", name: "Air China", logoSymbol: "airplane"),
        Airline(iataCode: "CZ", name: "China Southern", logoSymbol: "airplane"),
        Airline(iataCode: "BR", name: "EVA Air", logoSymbol: "airplane"),
        Airline(iataCode: "CI", name: "China Airlines", logoSymbol: "airplane"),
        // Timur Tengah
        Airline(iataCode: "EK", name: "Emirates", logoSymbol: "airplane"),
        Airline(iataCode: "QR", name: "Qatar Airways", logoSymbol: "airplane"),
        Airline(iataCode: "EY", name: "Etihad Airways", logoSymbol: "airplane"),
        Airline(iataCode: "TK", name: "Turkish Airlines", logoSymbol: "airplane"),
        Airline(iataCode: "SV", name: "Saudia", logoSymbol: "airplane"),
        // Eropa & Oceania
        Airline(iataCode: "BA", name: "British Airways", logoSymbol: "airplane"),
        Airline(iataCode: "LH", name: "Lufthansa", logoSymbol: "airplane"),
        Airline(iataCode: "AF", name: "Air France", logoSymbol: "airplane"),
        Airline(iataCode: "KL", name: "KLM", logoSymbol: "airplane"),
        Airline(iataCode: "QF", name: "Qantas", logoSymbol: "airplane"),
        Airline(iataCode: "NZ", name: "Air New Zealand", logoSymbol: "airplane"),
        // Semua maskapai
        Airline(iataCode: "ALL", name: "Semua Maskapai", logoSymbol: "airplane.circle"),
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

    // Detail record for lowest & highest price
    let lowestRecord: PriceRecord?   // full record with date, airline, flight number
    let highestRecord: PriceRecord?  // full record with date, airline, flight number
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
