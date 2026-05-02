// CheckScheduler.swift
// Periodically checks prices and sends notifications when new all-time lows are found

import Foundation
import UserNotifications
import Combine

@MainActor
final class CheckScheduler: ObservableObject {

    static let shared = CheckScheduler()

    @Published var isRunning = false
    @Published var lastCheckDate: Date?
    @Published var checkIntervalMinutes: Int = 60  // default: check every hour
    @Published var lastError: String?
    @Published var currentActivity: String = ""

    // Ringkasan rentang tanggal untuk ditampilkan di UI
    var dateRangeLabel: String { config.rangeLabel }

    private var timer: Timer?
    private let dataStore = DataStore.shared
    // nonisolated(unsafe) avoids Swift 6 data-race warning when calling async protocol method
    nonisolated(unsafe) private var scraper: FlightScraperProtocol = GoogleFlightsScraper()
    private var config = ScraperConfig.load()

    // Published results for UI
    @Published var latestOffers: [FlightOffer] = []
    @Published var recentNotifications: [PriceAlert] = []

    struct PriceAlert: Identifiable {
        var id = UUID()
        let routeKey: String
        let airline: String
        let price: Double
        let previousLow: Double?
        let flightDate: Date
        let flightNumber: String
        let alertDate: Date
        var priceFormatted: String {
            let f = NumberFormatter(); f.numberStyle = .currency
            f.locale = Locale(identifier: "id_ID"); f.maximumFractionDigits = 0
            return f.string(from: NSNumber(value: price)) ?? "Rp\(Int(price))"
        }
        var savingFormatted: String? {
            guard let prev = previousLow else { return nil }
            let saving = prev - price
            let f = NumberFormatter(); f.numberStyle = .currency
            f.locale = Locale(identifier: "id_ID"); f.maximumFractionDigits = 0
            return f.string(from: NSNumber(value: saving))
        }
    }

    private init() {
        reloadConfig()
    }

    func reloadConfig() {
        config = ScraperConfig.load()
        checkIntervalMinutes = UserDefaults.standard.integer(forKey: "check_interval_minutes")
            .clamped(to: 15...1440)
        if checkIntervalMinutes == 0 { checkIntervalMinutes = 60 }
        if config.useDemoMode {
            scraper = DemoFlightScraper()
        } else {
            scraper = GoogleFlightsScraper()
        }
    }

    // MARK: - Start/Stop

    func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleNextCheck()
        Task { await runCheck() }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    func runManualCheck() {
        Task { await runCheck() }
    }

    private func scheduleNextCheck() {
        timer?.invalidate()
        let interval = TimeInterval(checkIntervalMinutes * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.runCheck()
            }
        }
    }

    // MARK: - Core check logic

    func runCheck() async {
        // Ambil hanya rute yang benar-benar aktif dari DataStore
        // Tidak ada rute hardcoded — semua berasal dari input user
        let routes = dataStore.trackedRoutes.filter(\.isActive)
        guard !routes.isEmpty else {
            currentActivity = "Belum ada rute aktif. Tambahkan rute terlebih dahulu."
            return
        }

        lastCheckDate = Date()
        currentActivity = "Memeriksa \(routes.count) rute..."

        for trackedRoute in routes {
            // Double-check: pastikan rute ini benar-benar ada di DataStore
            guard dataStore.trackedRoutes.contains(where: { $0.id == trackedRoute.id && $0.isActive }) else {
                continue
            }
            await checkRoute(trackedRoute)
        }

        currentActivity = "Terakhir dicek: \(formattedDate(Date()))"
        lastError = nil
    }

    private func checkRoute(_ tracked: TrackedRoute) async {
        let route = tracked.route
        let routeKey = route.id

        var allNewRecords: [PriceRecord] = []
        var sessionOffers: [FlightOffer] = []

        let datesToCheck = config.datesToCheck()
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        df.locale = Locale(identifier: "id_ID")

        // ── Batch mode (Google Flights) ──────────────────────────────────────
        // If scraper is GoogleFlightsScraper, use batch mode for anti-detection
        if let gfScraper = scraper as? GoogleFlightsScraper, datesToCheck.count > 1 {
            let startLabel = df.string(from: datesToCheck.first!)
            let endLabel   = df.string(from: datesToCheck.last!)
            currentActivity = "\(route.origin.iataCode)→\(route.destination.iataCode): \(startLabel)–\(endLabel) (\(datesToCheck.count) hari)..."

            do {
                let result = try await gfScraper.scrapeDateRange(
                    origin: route.origin.iataCode,
                    destination: route.destination.iataCode,
                    dates: datesToCheck,
                    cabin: tracked.cabinClass,
                    delegate: nil
                )

                let elapsed = result.completedAt.timeIntervalSince(result.startedAt)
                currentActivity = "\(route.origin.iataCode)→\(route.destination.iataCode): \(result.totalFlights) penerbangan, \(result.datesScrapped)/\(datesToCheck.count) hari (\(Int(elapsed))s)"

                if !result.blockedDates.isEmpty {
                    lastError = "Terdeteksi blokir Google untuk \(result.blockedDates.count) tanggal. Coba lagi nanti."
                }

                // Filter offers by airline if needed
                var filtered = result.flights
                if tracked.airline != "ALL" {
                    filtered = filtered.filter { $0.airline == tracked.airline }
                }
                sessionOffers = filtered

                // Process all offers
                for offer in filtered {
                    let prevLow = dataStore.allTimeLow(
                        for: routeKey,
                        airline: offer.airline,
                        cabin: offer.cabinClass
                    )
                    let isLowest = prevLow == nil || offer.price < prevLow!

                    let record = PriceRecord(
                        routeKey: routeKey,
                        airline: offer.airline,
                        cabinClass: offer.cabinClass,
                        departureDate: offer.departureDate,
                        price: offer.price,
                        flightNumber: offer.flightNumber,
                        departureHour: offer.departureHour,
                        departureWeekday: offer.departureWeekday,
                        checkedAt: Date(),
                        isLowest: isLowest
                    )
                    allNewRecords.append(record)

                    if isLowest {
                        let alert = PriceAlert(
                            routeKey: routeKey,
                            airline: offer.airline,
                            price: offer.price,
                            previousLow: prevLow,
                            flightDate: offer.departureDate,
                            flightNumber: offer.flightNumber,
                            alertDate: Date()
                        )
                        recentNotifications.insert(alert, at: 0)
                        if recentNotifications.count > 50 { recentNotifications = Array(recentNotifications.prefix(50)) }

                        await sendNotification(route: route, offer: offer, previousLow: prevLow)
                    }
                }

            } catch {
                lastError = "Error batch-checking \(routeKey): \(error.localizedDescription)"
            }

        } else {
            // ── Single-date fallback (Demo or single date) ──────────────────────
            for (idx, checkDate) in datesToCheck.enumerated() {
                currentActivity = "Mengecek \(route.displayName) – \(df.string(from: checkDate)) (\(idx+1)/\(datesToCheck.count))..."

                do {
                    let offers = try await scraper.fetchOffers(
                        origin: route.origin.iataCode,
                        destination: route.destination.iataCode,
                        date: checkDate,
                        airline: tracked.airline,
                        cabin: tracked.cabinClass
                    )

                    sessionOffers.append(contentsOf: offers)

                    for offer in offers {
                        let prevLow = dataStore.allTimeLow(
                            for: routeKey,
                            airline: offer.airline,
                            cabin: offer.cabinClass
                        )
                        let isLowest = prevLow == nil || offer.price < prevLow!

                        let record = PriceRecord(
                            routeKey: routeKey,
                            airline: offer.airline,
                            cabinClass: offer.cabinClass,
                            departureDate: offer.departureDate,
                            price: offer.price,
                            flightNumber: offer.flightNumber,
                            departureHour: offer.departureHour,
                            departureWeekday: offer.departureWeekday,
                            checkedAt: Date(),
                            isLowest: isLowest
                        )
                        allNewRecords.append(record)

                        if isLowest {
                            let alert = PriceAlert(
                                routeKey: routeKey,
                                airline: offer.airline,
                                price: offer.price,
                                previousLow: prevLow,
                                flightDate: offer.departureDate,
                                flightNumber: offer.flightNumber,
                                alertDate: Date()
                            )
                            recentNotifications.insert(alert, at: 0)
                            if recentNotifications.count > 50 { recentNotifications = Array(recentNotifications.prefix(50)) }

                            await sendNotification(route: route, offer: offer, previousLow: prevLow)
                        }
                    }

                } catch {
                    lastError = "Error checking \(routeKey): \(error.localizedDescription)"
                }
            }
        }

        // Save records
        dataStore.addPriceRecords(allNewRecords)

        // Update tracked route's last check
        let lowestInSession = sessionOffers.map(\.price).min()
        dataStore.markRouteChecked(tracked.id, lowestPrice: lowestInSession)

        // Update UI
        latestOffers = sessionOffers.sorted { $0.price < $1.price }

        // Save session
        let lowestSessionPrice = allNewRecords.filter(\.isLowest).map(\.price).min()
        let session = CheckSession(
            routeKey: routeKey,
            airline: tracked.airline,
            cabinClass: tracked.cabinClass,
            checkedAt: Date(),
            offersFound: sessionOffers,
            lowestInSession: lowestInSession,
            isNewAllTimeLow: lowestSessionPrice != nil
        )
        dataStore.addCheckSession(session)
    }

    // MARK: - Notifications

    /// Kirim notifikasi menggunakan dua metode:
    /// 1. UNUserNotificationCenter (jika app punya izin dari System Settings)
    /// 2. osascript sebagai fallback yang selalu bekerja tanpa code signing
    private func sendNotification(route: Route, offer: FlightOffer, previousLow: Double?) async {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.locale = Locale(identifier: "id_ID")
        nf.maximumFractionDigits = 0

        let df = DateFormatter()
        df.dateFormat = "E, d MMM yyyy HH:mm"
        df.locale = Locale(identifier: "id_ID")

        let priceStr    = nf.string(from: NSNumber(value: offer.price)) ?? "Rp\(Int(offer.price))"
        let dateStr     = df.string(from: offer.departureDate)
        let title       = "✈️ Harga Terendah! \(route.origin.iataCode)→\(route.destination.iataCode)"
        let body: String

        if let prevLow = previousLow {
            let saving    = prevLow - offer.price
            let savingStr = nf.string(from: NSNumber(value: saving)) ?? "Rp\(Int(saving))"
            body = "\(offer.airlineName) – \(priceStr) | Terbang: \(dateStr) | Hemat \(savingStr)!"
        } else {
            body = "\(offer.airlineName) – \(priceStr) | Terbang: \(dateStr) | Harga terendah pertama!"
        }

        // — Metode 1: UNUserNotificationCenter (butuh izin resmi) —
        let center  = UNUserNotificationCenter.current()
        let status  = await center.notificationSettings().authorizationStatus
        if status == .authorized {
            let content           = UNMutableNotificationContent()
            content.title         = title
            content.body          = body
            content.sound         = .default
            let trigger           = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            let request           = UNNotificationRequest(
                identifier: "price-alert-\(offer.airline)-\(Int(offer.price))",
                content: content, trigger: trigger
            )
            try? await center.add(request)
            return
        }

        // — Metode 2: osascript fallback (tidak butuh izin UNUserNotificationCenter) —
        sendNotificationViaOsascript(title: title, body: body)
    }

    /// Kirim notifikasi lewat AppleScript — bekerja tanpa Developer ID signing.
    /// Muncul dari proses "Script Editor" tapi isinya tampil normal di Notification Center.
    private func sendNotificationViaOsascript(title: String, body: String) {
        // Escape tanda kutip agar tidak break AppleScript string
        let safeTitle = title.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let safeBody  = body.replacingOccurrences(of:  "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        display notification \"\(safeBody)\" with title \"\(safeTitle)\" sound name \"default\"
        """

        let proc        = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        proc.arguments  = ["-e", script]
        try? proc.run()
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df.string(from: date)
    }

    // MARK: - Request Notification Permission

    /// Coba minta izin UNUserNotificationCenter.
    /// Pada app ad-hoc signed ini akan error — kembalikan false tapi osascript tetap bisa jalan.
    func requestNotificationPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized { return true }
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        return granted
    }

    /// Kirim notifikasi test — hanya dipanggil dari tombol di Settings, tidak ada rute hardcoded
    func sendTestNotification() {
        let routeCount = dataStore.trackedRoutes.filter(\.isActive).count
        let routeNames = dataStore.trackedRoutes.filter(\.isActive)
            .map { $0.route.origin.iataCode + "→" + $0.route.destination.iataCode }
            .joined(separator: ", ")
        let body = routeCount > 0
            ? "Notifikasi aktif! Memantau \(routeCount) rute: \(routeNames)"
            : "Notifikasi aktif! Tambahkan rute untuk mulai memantau harga."
        sendNotificationViaOsascript(
            title: "✈️ Flight Price Tracker — Test Notifikasi",
            body: body
        )
    }
}
