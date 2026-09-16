//
//  HistoryView.swift
//  Água Diária
//
//  Aba "Histórico": gráfico de barras (Swift Charts, iOS 16+) e resumo.
//

import SwiftUI
import Charts

struct HistoryView: View {
    @EnvironmentObject private var store: WaterStore
    @State private var period: Period = .week

    enum Period: String, CaseIterable, Identifiable {
        case week = "7 dias"
        case month = "30 dias"

        var id: String { rawValue }
        var days: Int { self == .week ? 7 : 30 }
    }

    private var unit: VolumeUnit { store.settings.unit }
    private var totals: [DayTotal] { store.dailyTotals(lastDays: period.days) }
    private var goalValue: Double { unit.value(fromMilliliters: store.settings.dailyGoalML) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Período", selection: $period) {
                        ForEach(Period.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowSeparator(.hidden)

                    chart
                        .frame(height: 220)
                        .padding(.top, 10)
                        .padding(.bottom, 4)
                        .listRowSeparator(.hidden)
                } footer: {
                    Text("Valores em \(unit.shortName).")
                }

                Section("Resumo") {
                    HStack(alignment: .top, spacing: 8) {
                        StatCard(
                            title: "Média por dia",
                            value: unit.format(store.average(lastDays: period.days)),
                            systemImage: "chart.line.uptrend.xyaxis"
                        )
                        StatCard(
                            title: "Dias na meta",
                            value: "\(store.daysReachingGoal(lastDays: period.days))/\(period.days)",
                            systemImage: "target"
                        )
                        StatCard(
                            title: "Sequência",
                            value: "\(store.currentStreak)",
                            systemImage: "flame.fill"
                        )
                    }
                    .padding(.vertical, 6)
                }

                Section("Dia a dia") {
                    ForEach(Array(totals.reversed())) { day in
                        HStack {
                            Text(day.date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                            Spacer()
                            Text(unit.format(day.totalML))
                                .monospacedDigit()
                                .foregroundColor(day.totalML >= store.settings.dailyGoalML ? Theme.accent : .secondary)
                        }
                    }
                }
            }
            .navigationTitle("Histórico")
        }
    }

    // MARK: - Gráfico

    private var chart: some View {
        Chart {
            ForEach(totals) { day in
                BarMark(
                    x: .value("Dia", day.date, unit: .day),
                    y: .value("Total", unit.value(fromMilliliters: day.totalML))
                )
                .foregroundStyle(
                    day.totalML >= store.settings.dailyGoalML
                        ? Theme.accent
                        : Theme.accent.opacity(0.35)
                )
                .cornerRadius(4)
            }

            RuleMark(y: .value("Meta", goalValue))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                .foregroundStyle(Color.secondary)
                .annotation(position: .top, alignment: .trailing) {
                    Text("Meta \(unit.format(store.settings.dailyGoalML))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: period == .week ? 1 : 5)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: axisFormat)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }

    private var axisFormat: Date.FormatStyle {
        period == .week
            ? .dateTime.weekday(.narrow)
            : .dateTime.day().month(.narrow)
    }
}
