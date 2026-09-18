//
//  WaterStore.swift
//  Água Diária
//
//  Fonte única de verdade do app: registros + ajustes + persistência.
//  Usa a macro @Observable (iOS 17+) no lugar de ObservableObject, e
//  concorrência estruturada (async/await) para falar com o NotificationManager.
//

import Foundation

@MainActor
@Observable
final class WaterStore {

    /// Registros ordenados do mais recente para o mais antigo.
    private(set) var entries: [DrinkEntry] = []

    var settings: AppSettings {
        didSet { handleSettingsChange(from: oldValue) }
    }

    // MARK: - Infraestrutura

    private let calendar = Calendar.current
    private let defaults = UserDefaults.standard
    private let settingsKey = "aguadiaria.settings.v1"
    private let fileName = "aguadiaria-registros.json"

    private lazy var fileURL: URL = {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(fileName)
    }()

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init() {
        if let data = defaults.data(forKey: settingsKey),
           let saved = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = saved
        } else {
            settings = AppSettings()
        }
        loadEntries()
        Task { await NotificationManager.refresh(with: settings) }
    }

    // MARK: - Ações

    func add(amountML: Double, at date: Date = Date()) {
        guard amountML > 0 else { return }
        entries.append(DrinkEntry(date: date, amountML: amountML))
        entries.sort { $0.date > $1.date }
        save()
    }

    func delete(_ entry: DrinkEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    /// Apaga o registro mais recente de hoje (botão "desfazer").
    func undoLast() {
        guard let last = entriesForDay(Date()).first else { return }
        delete(last)
    }

    func addQuickAmount(_ amountML: Double) {
        guard amountML > 0, !settings.quickAmountsML.contains(amountML) else { return }
        settings.quickAmountsML.append(amountML)
        settings.quickAmountsML.sort()
    }

    func removeQuickAmounts(at offsets: IndexSet) {
        settings.quickAmountsML.remove(atOffsets: offsets)
    }

    func eraseAllData() {
        entries = []
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Consultas

    func entriesForDay(_ day: Date) -> [DrinkEntry] {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return entries.filter { $0.date >= start && $0.date < end }
    }

    func total(on day: Date) -> Double {
        entriesForDay(day).reduce(0) { $0 + $1.amountML }
    }

    var todayTotal: Double { total(on: Date()) }

    /// 0 = nada, 1 = meta batida. Pode passar de 1.
    var todayProgress: Double {
        guard settings.dailyGoalML > 0 else { return 0 }
        return todayTotal / settings.dailyGoalML
    }

    var remainingToday: Double {
        max(settings.dailyGoalML - todayTotal, 0)
    }

    /// Totais dos últimos `days` dias, do mais antigo para o mais recente.
    func dailyTotals(lastDays days: Int) -> [DayTotal] {
        let today = calendar.startOfDay(for: Date())
        var grouped: [Date: Double] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            grouped[day, default: 0] += entry.amountML
        }
        let result: [DayTotal] = (0..<max(days, 1)).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return DayTotal(date: day, totalML: grouped[day] ?? 0)
        }
        return Array(result.reversed())
    }

    func average(lastDays days: Int) -> Double {
        let totals = dailyTotals(lastDays: days)
        guard !totals.isEmpty else { return 0 }
        return totals.reduce(0) { $0 + $1.totalML } / Double(totals.count)
    }

    func daysReachingGoal(lastDays days: Int) -> Int {
        dailyTotals(lastDays: days).filter { $0.totalML >= settings.dailyGoalML }.count
    }

    /// Dias seguidos batendo a meta (o dia de hoje só conta depois de batido).
    var currentStreak: Int {
        let goal = settings.dailyGoalML
        guard goal > 0 else { return 0 }

        var day = calendar.startOfDay(for: Date())
        if total(on: day) < goal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while total(on: day) >= goal {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    // MARK: - Persistência

    func save() {
        do {
            let data = try encoder.encode(entries)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("⚠️ Não foi possível salvar os registros: \(error)")
        }
    }

    private func loadEntries() {
        guard let data = try? Data(contentsOf: fileURL),
              let saved = try? decoder.decode([DrinkEntry].self, from: data) else { return }
        entries = saved.sorted { $0.date > $1.date }
    }

    private func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
    }

    private func handleSettingsChange(from old: AppSettings) {
        saveSettings()

        let lembretesMudaram =
            old.remindersEnabled != settings.remindersEnabled ||
            old.reminderIntervalHours != settings.reminderIntervalHours ||
            old.reminderStartHour != settings.reminderStartHour ||
            old.reminderEndHour != settings.reminderEndHour

        if lembretesMudaram {
            let novosAjustes = settings
            Task { await NotificationManager.refresh(with: novosAjustes) }
        }
    }
}
