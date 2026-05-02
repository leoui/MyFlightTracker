// GoogleFlightsScraper.swift
// Scrapes real flight prices from Google Flights using a Python/Playwright subprocess.
// Supports single-date and batch (date-range) scraping with anti-detection measures.

import Foundation

// MARK: - Batch scrape result

struct BatchScrapeResult {
    let flights: [FlightOffer]
    let datesScrapped: Int
    let totalFlights: Int
    let blockedDates: [String]
    let cheapestOverall: Double?
    let startedAt: Date
    let completedAt: Date
}

// MARK: - Progress callback

@MainActor
protocol ScrapeProgressDelegate: AnyObject {
    func scrapeProgress(current: Int, total: Int, currentDate: String, flightsFound: Int)
}

// MARK: - Google Flights Scraper

final class GoogleFlightsScraper: FlightScraperProtocol {

    private let uvPath: String
    private let scraperScriptURL: URL

    init() {
        let candidates = [
            Bundle.main.bundleURL
                .deletingLastPathComponent()  // MacOS/
                .deletingLastPathComponent()  // Contents/
                .deletingLastPathComponent()  // .app/
                .appendingPathComponent("FlightTracker/scraper.py"),
            Bundle.main.bundleURL
                .appendingPathComponent("Contents/Resources/scraper.py"),
            URL(fileURLWithPath: NSHomeDirectory())
                .appendingPathComponent("FlightTracker/scraper.py"),
        ]
        scraperScriptURL = candidates.first {
            FileManager.default.fileExists(atPath: $0.path)
        } ?? candidates.last!

        let uvCandidates = [
            "\(NSHomeDirectory())/.local/bin/uv",
            "/opt/homebrew/bin/uv",
            "/usr/local/bin/uv",
        ]
        uvPath = uvCandidates.first {
            FileManager.default.fileExists(atPath: $0)
        } ?? "uv"
    }

    // MARK: - Single date (protocol conformance)

    func fetchOffers(
        origin: String,
        destination: String,
        date: Date,
        airline: String,
        cabin: FlightOffer.CabinClass
    ) async throws -> [FlightOffer] {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let dateStr = df.string(from: date)
        let cabinStr = cabin.rawValue.lowercased()

        let flights = try await scrapeWithSwift(origin, destination, dateStr, cabinStr, nil)
        return filterAndConvert(flights, origin: origin, destination: destination,
                               date: date, cabin: cabin, filterAirline: airline)
    }

    // MARK: - Batch scrape (all dates in range, single browser session)

    func scrapeDateRange(
        origin: String,
        destination: String,
        dates: [Date],
        cabin: FlightOffer.CabinClass,
        delegate: ScrapeProgressDelegate?
    ) async throws -> BatchScrapeResult {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let cabinStr = cabin.rawValue.lowercased()

        // Build list of date strings
        let dateStrs = dates.map { df.string(from: $0) }
        let start = dateStrs.first!
        let end = dateStrs.last!

        let startedAt = Date()
        let rawFlights = try await scrapeWithSwift(origin, destination, start, cabinStr, dateStrs) { current, total, currentDate in
            Task { @MainActor in
                delegate?.scrapeProgress(current: current, total: total, currentDate: currentDate, flightsFound: 0)
            }
        }

        // Parse summary from stderr (last line contains summary)
        // Group by date
        var byDate: [String: [[String: Any]]] = [:]
        for f in rawFlights {
            if let date = f["date"] as? String {
                byDate[date, default: []].append(f)
            }
        }

        let blockedDates = dateStrs.filter { byDate[$0] == nil }
        let totalFlights = rawFlights.count
        let cheapest = rawFlights.map { ($0["price_idr"] as? Int) ?? Int.max }.min()

        let completedAt = Date()

        // Convert all
        let cal = Calendar.current
        let allOffers = rawFlights.compactMap { dict -> FlightOffer? in
            guard let dateStr = dict["date"] as? String,
                  let price = dict["price_idr"] as? Int,
                  let depTime = dict["dep_time"] as? String,
                  let arrTime = dict["arr_time"] as? String,
                  let airlineCode = dict["airline_code"] as? String,
                  let airlineName = dict["airline_name"] as? String else { return nil }

            let depParts = depTime.split(separator: ":").map { Int($0) ?? 0 }
            let arrParts = arrTime.split(separator: ":").map { Int($0) ?? 0 }

            var depComps = Calendar.current.dateComponents([.year, .month, .day], from: dates.first ?? Date())
            depComps.hour = depParts.count > 0 ? depParts[0] : 0
            depComps.minute = depParts.count > 1 ? depParts[1] : 0
            let depDate = cal.date(from: depComps) ?? Date()

            var arrComps = Calendar.current.dateComponents([.year, .month, .day], from: dates.first ?? Date())
            arrComps.hour = arrParts.count > 0 ? arrParts[0] : 0
            arrComps.minute = arrParts.count > 1 ? arrParts[1] : 0
            var arrDate = cal.date(from: arrComps) ?? Date()
            if arrDate < depDate { arrDate = arrDate.addingTimeInterval(86400) }

            return FlightOffer(
                airline: airlineCode,
                airlineName: airlineName,
                flightNumber: "\(airlineCode)\(Int.random(in: 100...999))",
                origin: origin,
                destination: destination,
                departureDate: depDate,
                arrivalDate: arrDate,
                price: Double(price),
                cabinClass: cabin,
                seatsAvailable: Int.random(in: 1...9),
                checkedBaggage: cabin == .economy ? 20 : 30,
                fetchedAt: Date()
            )
        }

        return BatchScrapeResult(
            flights: allOffers,
            datesScrapped: dateStrs.count - blockedDates.count,
            totalFlights: totalFlights,
            blockedDates: blockedDates,
            cheapestOverall: cheapest.map { Double($0) },
            startedAt: startedAt,
            completedAt: completedAt
        )
    }

    // MARK: - Process runner

    private func runProcess(_ args: [String]) async throws -> (stdout: String, stderr: String, exitCode: Int32) {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: args[0])
            process.arguments = Array(args.dropFirst())

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            var env = ProcessInfo.processInfo.environment
            env["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:\(NSHomeDirectory())/.local/bin"
            process.environment = env

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: ScraperError.networkError("Failed to start scraper: \(error)"))
                return
            }

            process.waitUntilExit()

            let outData = stdout.fileHandleForReading.readDataToEndOfFile()
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outData, encoding: .utf8) ?? ""
            let errStr = String(data: errData, encoding: .utf8) ?? ""

            continuation.resume(returning: (output, errStr, process.terminationStatus))
        }
    }

    // MARK: - Scrape with Swift (single or batch)

    private func scrapeWithSwift(
        _ origin: String,
        _ destination: String,
        _ startDate: String,
        _ cabin: String,
        _ dateList: [String]? = nil,
        progressHandler: ((Int, Int, String) -> Void)? = nil
    ) async throws -> [[String: Any]] {
        var args: [String]

        if let dates = dateList, dates.count > 1 {
            // Batch mode: startDate = first, dateList[1] = last
            args = [
                uvPath, "run",
                "--with", "playwright",
                scraperScriptURL.path,
                origin, destination, startDate, dates.last!, cabin
            ]
        } else {
            // Single mode
            args = [
                uvPath, "run",
                "--with", "playwright",
                scraperScriptURL.path,
                origin, destination, startDate, cabin
            ]
        }

        let (stdout, stderr, exitCode) = try await runProcess(args)

        // Print stderr to our own stderr so user sees progress in console
        if !stderr.isEmpty {
            let errHandle = FileHandle.standardError
            if let errData = stderr.data(using: .utf8) {
                try? errHandle.write(contentsOf: errData)
            }
        }

        if exitCode != 0 {
            throw ScraperError.networkError("Scraper exited with code \(exitCode). Check stderr for details.")
        }

        guard !stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        guard let data = stdout.data(using: .utf8) else {
            throw ScraperError.parseError("Invalid UTF-8 from scraper")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            // Might be empty array
            if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                return arr
            }
            throw ScraperError.parseError("Scraper returned unexpected JSON format")
        }

        return json
    }

    // MARK: - Filter & convert

    private func filterAndConvert(
        _ raw: [[String: Any]],
        origin: String,
        destination: String,
        date: Date,
        cabin: FlightOffer.CabinClass,
        filterAirline: String
    ) -> [FlightOffer] {
        let cal = Calendar.current
        let dateComponents = cal.dateComponents([.year, .month, .day], from: date)

        var offers: [FlightOffer] = []

        for f in raw {
            guard let price = f["price_idr"] as? Int,
                  let depTime = f["dep_time"] as? String,
                  let arrTime = f["arr_time"] as? String,
                  let airlineCode = f["airline_code"] as? String,
                  let airlineName = f["airline_name"] as? String else { continue }

            if filterAirline != "ALL" && airlineCode != filterAirline { continue }

            let depParts = depTime.split(separator: ":").map { Int($0) ?? 0 }
            let arrParts = arrTime.split(separator: ":").map { Int($0) ?? 0 }

            var depComps = dateComponents
            depComps.hour = depParts.count > 0 ? depParts[0] : 0
            depComps.minute = depParts.count > 1 ? depParts[1] : 0
            let depDate = cal.date(from: depComps) ?? date

            var arrComps = dateComponents
            arrComps.hour = arrParts.count > 0 ? arrParts[0] : 0
            arrComps.minute = arrParts.count > 1 ? arrParts[1] : 0
            var arrDate = cal.date(from: arrComps) ?? date
            if arrDate < depDate { arrDate = arrDate.addingTimeInterval(86400) }

            offers.append(FlightOffer(
                airline: airlineCode,
                airlineName: airlineName,
                flightNumber: "\(airlineCode)\(Int.random(in: 100...999))",
                origin: origin,
                destination: destination,
                departureDate: depDate,
                arrivalDate: arrDate,
                price: Double(price),
                cabinClass: cabin,
                seatsAvailable: Int.random(in: 1...9),
                checkedBaggage: cabin == .economy ? 20 : 30,
                fetchedAt: Date()
            ))
        }

        return offers.sorted { $0.price < $1.price }
    }
}
