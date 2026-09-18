//
//  TodayView.swift
//  Água Diária
//
//  Aba "Hoje": o quanto já foi bebido, atalhos de registro e a lista do dia.
//
//  Usa @Environment(WaterStore.self) (padrão @Observable) no lugar de
//  @EnvironmentObject.
//

import SwiftUI

struct TodayView: View {
    @Environment(WaterStore.self) private var store
    @State private var showingCustomAmount = false

    private var unit: VolumeUnit { store.settings.unit }
    private var todayEntries: [DrinkEntry] { store.entriesForDay(Date()) }

    var body: some View {
        NavigationStack {
            List {
                progressSection
                quickAddSection
                entriesSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Hoje")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { store.undoLast() }
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(todayEntries.isEmpty)
                    .accessibilityLabel("Desfazer último registro")
                }
            }
            .sheet(isPresented: $showingCustomAmount) {
                AmountInputSheet(
                    title: "Outro valor",
                    unit: unit,
                    confirmTitle: "Adicionar"
                ) { amountML in
                    add(amountML)
                }
            }
        }
    }

    // MARK: - Seções

    private var progressSection: some View {
        Section {
            VStack(spacing: 14) {
                WaterRingView(
                    progress: store.todayProgress,
                    centerValue: unit.format(store.todayTotal, includeUnit: false),
                    centerUnit: unit.shortName,
                    caption: "de \(unit.format(store.settings.dailyGoalML))"
                )
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .liquidGlassCard()
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private var quickAddSection: some View {
        Section("Adicionar") {
            LiquidGlassGroup {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 76), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(store.settings.quickAmountsML, id: \.self) { amountML in
                        QuickAddButton(
                            label: unit.format(amountML),
                            symbol: DrinkSymbol.name(forML: amountML)
                        ) {
                            add(amountML)
                        }
                    }
                    QuickAddButton(label: "Outro", symbol: "plus") {
                        showingCustomAmount = true
                    }
                }
            }
            .padding(.vertical, 6)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private var entriesSection: some View {
        Section {
            if todayEntries.isEmpty {
                Text("Nada registrado ainda. Toque em um atalho acima.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(todayEntries) { entry in
                    HStack(spacing: 12) {
                        Image(systemName: DrinkSymbol.name(forML: entry.amountML))
                            .foregroundColor(Theme.accent)
                            .frame(width: 22)
                        Text(unit.format(entry.amountML))
                            .monospacedDigit()
                        Spacer()
                        Text(entry.date, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }
                .onDelete(perform: deleteEntries)
            }
        } header: {
            Text("Registros de hoje")
        } footer: {
            if !todayEntries.isEmpty {
                Text("Arraste um registro para o lado para apagar.")
            }
        }
    }

    // MARK: - Lógica da tela

    private var statusMessage: String {
        let progress = store.todayProgress
        let remaining = unit.format(store.remainingToday)

        if progress <= 0 {
            return "Comece com um copo d'água."
        } else if progress < 0.5 {
            return "Bom começo. Faltam \(remaining)."
        } else if progress < 1 {
            return "Quase lá — faltam \(remaining)."
        } else if store.currentStreak > 1 {
            return "Meta batida. \(store.currentStreak) dias seguidos."
        } else {
            return "Meta batida hoje."
        }
    }

    private func add(_ amountML: Double) {
        let goal = store.settings.dailyGoalML
        let antes = store.todayTotal
        withAnimation { store.add(amountML: amountML) }

        if antes < goal && store.todayTotal >= goal {
            Haptics.play(.success)
        } else {
            Haptics.play(.light)
        }
    }

    private func deleteEntries(at offsets: IndexSet) {
        let atuais = todayEntries
        for index in offsets where atuais.indices.contains(index) {
            store.delete(atuais[index])
        }
    }
}

#Preview {
    TodayView()
        .environment(WaterStore())
}
