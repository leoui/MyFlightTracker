// PriceChartView.swift – Price history chart and pattern analysis

import SwiftUI
import Charts

struct PriceHistoryChartView: View {
    let records: [PriceRecord]
    let routeKey: String

    private var chartData: [(date: Date, price: Double, airline: String)] {
        records.map { ($0.checkedAt, $0.price, $0.airline) }
    }

    private var lowestEver: Double? { records.map(\.price).min() }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Riwayat Harga")
                .font(.headline)

            if records.isEmpty {
                ContentUnavailableView(
                    "Belum Ada Data",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("Mulai monitoring untuk melihat riwayat harga")
                )
                .frame(height: 200)
            } else {
                Chart {
                    ForEach(chartData, id: \.date) { point in
                        LineMark(
                            x: .value("Tanggal", point.date),
                            y: .value("Harga", point.price)
                        )
                        .foregroundStyle(by: .value("Maskapai", point.airline))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Tanggal", point.date),
                            y: .value("Harga", point.price)
                        )
                        .foregroundStyle(by: .value("Maskapai", point.airline))
                    }

                    // Lowest price line
                    if let low = lowestEver {
                        RuleMark(y: .value("Terendah", low))
                            .foregroundStyle(.green.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                            .annotation(position: .leading) {
                                Text("Min")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatIDR(v))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine()
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                            .font(.caption2)
                    }
                }
                .frame(height: 220)
                .padding(.vertical, 4)
            }
        }
    }

    private func formatIDR(_ value: Double) -> String {
        let millions = value / 1_000_000
        if millions >= 1 {
            return String(format: "%.1fJt", millions)
        }
        let thousands = value / 1_000
        return String(format: "%.0fRb", thousands)
    }
}

// MARK: - Pattern Analysis View

struct PricePatternView: View {
    let pattern: PricePattern

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pola Harga")
                .font(.headline)

            // Summary cards
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                PatternCard(
                    title: "Jam Termurah",
                    value: String(format: "%02d:00", pattern.bestHour),
                    subtitle: hourCategory(pattern.bestHour),
                    color: .green,
                    icon: "clock.fill"
                )
                PatternCard(
                    title: "Hari Termurah",
                    value: pattern.bestWeekday.weekdayShortName,
                    subtitle: weekdayName(pattern.bestWeekday),
                    color: .blue,
                    icon: "calendar"
                )
                PatternCard(
                    title: "Harga Terendah",
                    value: formatIDRShort(pattern.lowestEver),
                    subtitle: "\(pattern.sampleCount) data",
                    color: .purple,
                    icon: "tag.fill"
                )
            }

            // Hour heatmap
            if !pattern.avgPriceByHour.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Harga Rata-rata per Jam Keberangkatan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Chart {
                        ForEach(0..<24, id: \.self) { hour in
                            if let avg = pattern.avgPriceByHour[hour] {
                                BarMark(
                                    x: .value("Jam", "\(hour)"),
                                    y: .value("Harga", avg)
                                )
                                .foregroundStyle(
                                    hour == pattern.bestHour ? Color.green : Color.blue.opacity(0.6)
                                )
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { val in
                            AxisValueLabel {
                                if let v = val.as(Double.self) {
                                    Text(formatIDRShort(v)).font(.caption2)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: 3)) { val in
                            AxisValueLabel {
                                if let s = val.as(String.self) {
                                    Text(s + "h").font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 120)

                    Text("🟢 = jam dengan harga terendah rata-rata")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Weekday chart
            if !pattern.avgPriceByWeekday.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Harga Rata-rata per Hari Keberangkatan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Chart {
                        ForEach(1...7, id: \.self) { day in
                            if let avg = pattern.avgPriceByWeekday[day] {
                                BarMark(
                                    x: .value("Hari", day.weekdayShortName),
                                    y: .value("Harga", avg)
                                )
                                .foregroundStyle(
                                    day == pattern.bestWeekday ? Color.green : Color.orange.opacity(0.7)
                                )
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { val in
                            AxisValueLabel {
                                if let v = val.as(Double.self) {
                                    Text(formatIDRShort(v)).font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 100)

                    Text("🟢 = hari dengan harga terendah rata-rata")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func formatIDRShort(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "%.1fJt", value / 1_000_000) }
        return String(format: "%.0fRb", value / 1_000)
    }

    private func hourCategory(_ hour: Int) -> String {
        switch hour {
        case 0...5:   return "Tengah Malam"
        case 6...11:  return "Pagi"
        case 12...17: return "Siang"
        case 18...21: return "Sore/Malam"
        default:      return "Malam"
        }
    }

    private func weekdayName(_ day: Int) -> String {
        let names = ["Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"]
        guard day >= 1 && day <= 7 else { return "" }
        return names[day - 1]
    }
}

// MARK: - Pattern Card

struct PatternCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}
