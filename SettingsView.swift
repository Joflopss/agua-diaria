//
//  SettingsView.swift
//  Água Diária
//
//  Aba "Ajustes": meta, unidade, atalhos, lembretes e dados.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: WaterStore

    @State private var showingGoalCalculator = false
    @State private var showingNewQuickAmount = false
    @State private var showingEraseAlert = false
    @State private var showingPermissionAlert = false

    private var unit: VolumeUnit { store.settings.unit }

    var body: some View {
        NavigationStack {
            Form {
                goalSection
                unitSection
                quickAmountsSection
                remindersSection
                dataSection
            }
            .navigationTitle("Ajustes")
            .sheet(isPresented: $showingGoalCalculator) {
                GoalCalculatorSheet().environmentObject(store)
            }
            .sheet(isPresented: $showingNewQuickAmount) {
                AmountInputSheet(
                    title: "Novo atalho",
                    unit: unit,
                    confirmTitle: "Salvar atalho"
                ) { amountML in
                    store.addQuickAmount(amountML)
                }
            }
            .alert("Apagar todos os registros?", isPresented: $showingEraseAlert) {
                Button("Apagar", role: .destructive) { store.eraseAllData() }
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("O histórico será removido deste iPhone e não poderá ser recuperado.")
            }
            .alert("Notificações bloqueadas", isPresented: $showingPermissionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Libere as notificações do app em Ajustes do iPhone > Notificações para receber os lembretes.")
            }
        }
    }

    // MARK: - Meta

    private var goalSection: some View {
        Section {
            Stepper(
                value: goalBinding,
                in: unit.value(fromMilliliters: 500)...unit.value(fromMilliliters: 6000),
                step: unit.step
            ) {
                HStack {
                    Text("Meta diária")
                    Spacer()
                    Text(unit.format(store.settings.dailyGoalML))
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }

            Button {
                showingGoalCalculator = true
            } label: {
                Label("Calcular meta pelo peso", systemImage: "function")
            }
        } header: {
            Text("Meta")
        } footer: {
            Text("Uma referência comum é 35 ml por quilo de peso ao dia. Clima, atividade física e orientação médica mudam esse número.")
        }
    }

    private var goalBinding: Binding<Double> {
        Binding(
            get: { unit.value(fromMilliliters: store.settings.dailyGoalML) },
            set: { store.settings.dailyGoalML = unit.milliliters(from: $0) }
        )
    }

    // MARK: - Unidade

    private var unitSection: some View {
        Section("Unidade") {
            Picker("Unidade", selection: $store.settings.unit) {
                ForEach(VolumeUnit.allCases) { item in
                    Text(item.displayName).tag(item)
                }
            }
        }
    }

    // MARK: - Atalhos

    private var quickAmountsSection: some View {
        Section {
            ForEach(store.settings.quickAmountsML, id: \.self) { amountML in
                HStack(spacing: 12) {
                    Image(systemName: DrinkSymbol.name(forML: amountML))
                        .foregroundColor(Theme.accent)
                        .frame(width: 22)
                    Text(unit.format(amountML))
                        .monospacedDigit()
                }
            }
            .onDelete { offsets in
                store.removeQuickAmounts(at: offsets)
            }

            Button {
                showingNewQuickAmount = true
            } label: {
                Label("Adicionar atalho", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Atalhos de registro")
        } footer: {
            Text("São os botões que aparecem na aba Hoje. Arraste para o lado para remover.")
        }
    }

    // MARK: - Lembretes

    private var remindersSection: some View {
        Section {
            Toggle("Lembretes de hidratação", isOn: remindersBinding)

            if store.settings.remindersEnabled {
                Picker("A cada", selection: $store.settings.reminderIntervalHours) {
                    ForEach([1, 2, 3, 4], id: \.self) { hours in
                        Text(hours == 1 ? "1 hora" : "\(hours) horas").tag(hours)
                    }
                }
                Picker("Começar às", selection: $store.settings.reminderStartHour) {
                    hourOptions
                }
                Picker("Parar às", selection: $store.settings.reminderEndHour) {
                    hourOptions
                }
            }
        } header: {
            Text("Lembretes")
        } footer: {
            Text("As notificações se repetem todos os dias nos horários escolhidos.")
        }
    }

    private var hourOptions: some View {
        ForEach(0..<24, id: \.self) { hour in
            Text(String(format: "%02d:00", hour)).tag(hour)
        }
    }

    private var remindersBinding: Binding<Bool> {
        Binding(
            get: { store.settings.remindersEnabled },
            set: { novoValor in
                guard novoValor else {
                    store.settings.remindersEnabled = false
                    return
                }
                NotificationManager.requestAuthorization { granted in
                    store.settings.remindersEnabled = granted
                    showingPermissionAlert = !granted
                }
            }
        )
    }

    // MARK: - Dados

    private var dataSection: some View {
        Section {
            Button(role: .destructive) {
                showingEraseAlert = true
            } label: {
                Label("Apagar todos os registros", systemImage: "trash")
            }
        } header: {
            Text("Dados")
        } footer: {
            Text("Água Diária 1.0 — tudo fica salvo apenas neste iPhone.")
        }
    }
}

// MARK: - Calculadora de meta

struct GoalCalculatorSheet: View {
    @EnvironmentObject private var store: WaterStore
    @Environment(\.dismiss) private var dismiss

    @State private var weight: Double = 70
    @State private var activity: ActivityLevel = .moderate

    enum ActivityLevel: String, CaseIterable, Identifiable {
        case light = "Leve"
        case moderate = "Moderada"
        case intense = "Intensa"

        var id: String { rawValue }

        var extraML: Double {
            switch self {
            case .light:     return 0
            case .moderate:  return 350
            case .intense:   return 700
            }
        }
    }

    private var suggestedML: Double { (weight * 35) + activity.extraML }

    var body: some View {
        NavigationStack {
            Form {
                Section("Peso") {
                    VStack(spacing: 8) {
                        Text("\(Int(weight)) kg")
                            .font(.title2.weight(.semibold))
                            .monospacedDigit()
                        Slider(value: $weight, in: 30...150, step: 1)
                    }
                    .padding(.vertical, 4)
                }

                Section("Atividade física") {
                    Picker("Nível", selection: $activity) {
                        ForEach(ActivityLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HStack {
                        Text("Meta sugerida")
                        Spacer()
                        Text(store.settings.unit.format(suggestedML))
                            .font(.headline)
                            .foregroundColor(Theme.accent)
                            .monospacedDigit()
                    }
                    Button("Usar esta meta") {
                        store.settings.dailyGoalML = (suggestedML / 50).rounded() * 50
                        dismiss()
                    }
                } footer: {
                    Text("Estimativa geral, arredondada para múltiplos de 50 ml. Não substitui orientação de um profissional de saúde.")
                }
            }
            .navigationTitle("Calcular meta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
}
