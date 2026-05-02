// AlertsHistoryView.swift – Full list of price alerts

import SwiftUI

struct AlertsHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var scheduler = CheckScheduler.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Riwayat Notifikasi Harga")
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

            if scheduler.recentNotifications.isEmpty {
                ContentUnavailableView(
                    "Belum Ada Notifikasi",
                    systemImage: "bell.slash",
                    description: Text("Notifikasi akan muncul di sini saat harga mencapai titik terendah baru")
                )
            } else {
                List(scheduler.recentNotifications) { alert in
                    AlertRow(alert: alert)
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 500, height: 450)
    }
}

struct AlertRow: View {
    let alert: CheckScheduler.PriceAlert

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(alert.routeKey)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(alert.airline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Text(alert.priceFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)

                    if let saving = alert.savingFormatted {
                        Text("(hemat \(saving))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("(pertama kali tercatat)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    Label(alert.flightNumber, systemImage: "airplane")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Label(alert.flightDate.formatted(.dateTime.day().month().hour().minute()),
                          systemImage: "calendar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(alert.alertDate.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
