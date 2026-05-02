// AddRouteView.swift – Form to add a new tracked route with search/autocomplete

import SwiftUI

struct AddRouteView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataStore = DataStore.shared

    @State private var selectedOrigin: Airport? = nil
    @State private var selectedDestination: Airport? = nil
    @State private var selectedAirline: String = "ALL"
    @State private var selectedCabin: FlightOffer.CabinClass = .economy
    @State private var useThresholdAlert = false
    @State private var thresholdAmount: String = ""
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Tambah Rute Baru")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.bar)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Route section — search autocomplete
                    GroupBox {
                        VStack(spacing: 14) {
                            AirportSearchField(
                                label: "🛫 Asal",
                                placeholder: "Ketik kota, nama bandara, atau kode IATA...",
                                selectedAirport: $selectedOrigin
                            )

                            Divider()

                            AirportSearchField(
                                label: "🛬 Tujuan",
                                placeholder: "Ketik kota, nama bandara, atau kode IATA...",
                                selectedAirport: $selectedDestination
                            )
                        }
                    } label: {
                        Label("Rute Penerbangan", systemImage: "airplane")
                            .font(.subheadline).fontWeight(.semibold)
                    }

                    // Airline section
                    GroupBox {
                        VStack(spacing: 12) {
                            LabeledAirlinePicker(label: "✈️ Maskapai", selection: $selectedAirline)
                            Divider()
                            LabeledCabinPicker(label: "💺 Kelas", selection: $selectedCabin)
                        }
                    } label: {
                        Label("Maskapai & Kelas", systemImage: "person.crop.square")
                            .font(.subheadline).fontWeight(.semibold)
                    }

                    // Alert section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Notifikasi otomatis saat harga baru terendah", isOn: .constant(true))
                                .disabled(true)
                                .foregroundStyle(.secondary)
                                .font(.caption)

                            Divider()

                            Toggle("Notifikasi jika harga di bawah batas tertentu", isOn: $useThresholdAlert)
                                .font(.subheadline)

                            if useThresholdAlert {
                                HStack {
                                    Text("Batas harga (IDR):")
                                        .font(.subheadline)
                                    TextField("contoh: 800000", text: $thresholdAmount)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 180)
                                }
                            }
                        }
                    } label: {
                        Label("Pengaturan Notifikasi", systemImage: "bell.badge")
                            .font(.subheadline).fontWeight(.semibold)
                    }

                    if let error {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.horizontal, 4)
                    }

                    // Validation hint
                    if let o = selectedOrigin, let d = selectedDestination, o.iataCode == d.iataCode {
                        Label("Asal dan tujuan tidak boleh sama", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                .padding()
            }

            Divider()

            // Footer buttons
            HStack {
                Button("Batal") { dismiss() }
                    .keyboardShortcut(.escape)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: save) {
                    Label("Tambah Rute", systemImage: "plus.circle.fill")
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(selectedOrigin == nil || selectedDestination == nil ||
                          selectedOrigin?.iataCode == selectedDestination?.iataCode)
            }
            .padding()
            .background(.bar)
        }
        .frame(width: 480, height: 620)
    }

    private func save() {
        guard let origin = selectedOrigin, let dest = selectedDestination else {
            error = "Pilih bandara asal dan tujuan."
            return
        }
        guard origin.iataCode != dest.iataCode else {
            error = "Asal dan tujuan tidak boleh sama."
            return
        }

        // Check duplicate
        let routeKey = "\(origin.iataCode)-\(dest.iataCode)"
        let exists = dataStore.trackedRoutes.contains {
            $0.route.id == routeKey && $0.airline == selectedAirline && $0.cabinClass == selectedCabin
        }
        if exists {
            error = "Rute ini sudah ditambahkan sebelumnya."
            return
        }

        let threshold: Double? = useThresholdAlert
            ? Double(thresholdAmount.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: ".", with: ""))
            : nil

        let route = Route(origin: origin, destination: dest)
        let tracked = TrackedRoute(
            route: route,
            airline: selectedAirline,
            cabinClass: selectedCabin,
            isActive: true,
            alertThreshold: threshold,
            createdAt: Date()
        )

        dataStore.addTrackedRoute(tracked)
        dismiss()
    }
}

// MARK: - AirportSearchField (autocomplete)

struct AirportSearchField: View {
    let label: String
    let placeholder: String
    @Binding var selectedAirport: Airport?

    @State private var searchText: String = ""
    @State private var isEditing: Bool = false
    @State private var hoveredAirport: Airport? = nil

    private var filteredAirports: [Airport] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return [] }

        // Split into two sections: domestic first, then international
        let domesticMatches = Airport.domestic.filter { matchesSearch($0, q) }
        let intlMatches = Airport.international.filter { matchesSearch($0, q) }

        // Limit to 8 results per section to keep dropdown compact
        var results: [Airport] = []
        results.append(contentsOf: domesticMatches.prefix(8))
        if domesticMatches.count <= 8 {
            results.append(contentsOf: intlMatches.prefix(8 - domesticMatches.count))
        }
        if domesticMatches.count > 8 {
            results.append(contentsOf: intlMatches.prefix(max(0, 8 - domesticMatches.count)))
        }

        // Prioritize exact IATA code matches
        let exactIATA = Airport.all.filter { $0.iataCode.lowercased() == q }
        if let exact = exactIATA.first, !results.contains(where: { $0.iataCode == exact.iataCode }) {
            results.insert(exact, at: 0)
        }

        // Remove duplicates while preserving order
        var seen = Set<String>()
        return results.filter { seen.insert($0.iataCode).inserted }.prefix(10).map { $0 }
    }

    private func matchesSearch(_ airport: Airport, _ q: String) -> Bool {
        airport.iataCode.lowercased().contains(q) ||
        airport.city.lowercased().contains(q) ||
        airport.name.lowercased().contains(q) ||
        airport.country.lowercased().contains(q)
    }

    // Whether we should show domestic/international section headers
    private var hasDomestic: Bool { filteredAirports.contains { $0.country == "Indonesia" } }
    private var hasInternational: Bool { filteredAirports.contains { $0.country != "Indonesia" } }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .frame(width: 70, alignment: .leading)

                ZStack(alignment: .leading) {
                    // Show selected airport chip or empty state
                    if let selected = selectedAirport {
                        HStack(spacing: 6) {
                            Text("✈️ \(selected.city) (\(selected.iataCode))")
                                .font(.subheadline)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.15))
                                .clipShape(Capsule())
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    selectedAirport = nil
                                    searchText = ""
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Search field (always visible for editing)
                    if selectedAirport == nil || isEditing {
                        TextField(placeholder, text: $searchText, onEditingChanged: { editing in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                isEditing = editing
                            }
                        })
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                        .onChange(of: searchText) { _, _ in
                            hoveredAirport = nil
                        }
                    } else {
                        // Tap on chip area to re-open search
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    isEditing = true
                                    searchText = ""
                                    selectedAirport = nil
                                }
                            }
                    }
                }
            }

            // Autocomplete dropdown
            if isEditing && !searchText.trimmingCharacters(in: .whitespaces).isEmpty && !filteredAirports.isEmpty {
                VStack(spacing: 0) {
                    // Domestic section
                    let domestic = filteredAirports.filter { $0.country == "Indonesia" }
                    if !domestic.isEmpty {
                        sectionHeader("🇮🇩 Domestik")
                        ForEach(domestic) { airport in
                            airportRow(airport)
                        }
                    }

                    // International section
                    let intl = filteredAirports.filter { $0.country != "Indonesia" }
                    if !intl.isEmpty {
                        if hasDomestic && hasInternational {
                            Divider().padding(.vertical, 2)
                        }
                        sectionHeader("🌏 Internasional")
                        ForEach(intl) { airport in
                            airportRow(airport)
                        }
                    }
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 3)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func airportRow(_ airport: Airport) -> some View {
        let isHovered = hoveredAirport?.id == airport.id

        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedAirport = airport
                searchText = ""
                isEditing = false
            }
        }) {
            HStack {
                Text(airport.iataCode)
                    .font(.subheadline).fontWeight(.semibold)
                    .frame(width: 40, alignment: .leading)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text(airport.city)
                        .font(.subheadline)
                        .lineLimit(1)
                    Text(airport.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(airport.country)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHovered ? Color.accentColor.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredAirport = hovering ? airport : (hoveredAirport?.id == airport.id ? nil : hoveredAirport)
        }
    }
}

// MARK: - LabeledAirlinePicker

struct LabeledAirlinePicker: View {
    let label: String
    @Binding var selection: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .frame(width: 90, alignment: .leading)
            Picker("", selection: $selection) {
                ForEach(Airline.popular, id: \.iataCode) { a in
                    Text(a.name).tag(a.iataCode)
                }
            }
            .labelsHidden()
        }
    }
}

// MARK: - LabeledCabinPicker

struct LabeledCabinPicker: View {
    let label: String
    @Binding var selection: FlightOffer.CabinClass

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .frame(width: 90, alignment: .leading)
            Picker("", selection: $selection) {
                ForEach(FlightOffer.CabinClass.allCases, id: \.self) { c in
                    Text(c.rawValue).tag(c)
                }
            }
            .labelsHidden()
            .pickerStyle(.segmented)
        }
    }
}
