// AddRouteView.swift – Form to add a new tracked route

import SwiftUI

struct AddRouteView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var dataStore = DataStore.shared

    @State private var selectedOrigin: Airport = Airport.popular[0]
    @State private var selectedDestination: Airport = Airport.popular[2]
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

                    // Route section
                    GroupBox {
                        VStack(spacing: 12) {
                            LabeledPicker(label: "🛫 Asal", selection: $selectedOrigin,
                                          options: Airport.popular) { $0.city + " (\($0.iataCode))" }

                            Divider()

                            LabeledPicker(label: "🛬 Tujuan", selection: $selectedDestination,
                                          options: Airport.popular) { $0.city + " (\($0.iataCode))" }
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
                    if selectedOrigin.iataCode == selectedDestination.iataCode {
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
                .disabled(selectedOrigin.iataCode == selectedDestination.iataCode)
            }
            .padding()
            .background(.bar)
        }
        .frame(width: 440, height: 520)
    }

    private func save() {
        guard selectedOrigin.iataCode != selectedDestination.iataCode else {
            error = "Asal dan tujuan tidak boleh sama."
            return
        }

        // Check duplicate
        let routeKey = "\(selectedOrigin.iataCode)-\(selectedDestination.iataCode)"
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

        let route = Route(origin: selectedOrigin, destination: selectedDestination)
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

// MARK: - Helper sub-views

struct LabeledPicker<T: Hashable>: View {
    let label: String
    @Binding var selection: T
    let options: [T]
    let title: (T) -> String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .frame(width: 90, alignment: .leading)
            Picker("", selection: $selection) {
                ForEach(options, id: \.self) { opt in
                    Text(title(opt)).tag(opt)
                }
            }
            .labelsHidden()
        }
    }
}

struct LabeledAirlinePicker: View {
    let label: String
    @Binding var selection: String

    private let airlines: [(code: String, name: String)] = [
        ("ALL", "Semua Maskapai"),
        ("GA", "Garuda Indonesia"),
        ("JT", "Lion Air"),
        ("SJ", "Sriwijaya Air"),
        ("ID", "Batik Air"),
        ("IW", "Wings Air"),
        ("IN", "Nam Air"),
        ("QZ", "AirAsia Indonesia"),
        ("SQ", "Singapore Airlines"),
        ("MH", "Malaysia Airlines"),
        ("EK", "Emirates"),
        ("QR", "Qatar Airways"),
    ]

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .frame(width: 90, alignment: .leading)
            Picker("", selection: $selection) {
                ForEach(airlines, id: \.code) { a in
                    Text(a.name).tag(a.code)
                }
            }
            .labelsHidden()
        }
    }
}

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
