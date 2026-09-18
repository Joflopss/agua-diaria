//
//  Models.swift
//  Água Diária
//
//  Modelos de dados. Sem dependências de UI — só Foundation.
//

import Foundation

// MARK: - Unidade de volume

enum VolumeUnit: String, Codable, CaseIterable, Identifiable, Sendable {
    case milliliters
    case fluidOunces

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .milliliters:  return "ml"
        case .fluidOunces:  return "oz"
        }
    }

    var displayName: String {
        switch self {
        case .milliliters:  return "Mililitros (ml)"
        case .fluidOunces:  return "Onças líquidas (fl oz)"
        }
    }

    /// Quantos mililitros valem 1 unidade.
    var millilitersPerUnit: Double {
        switch self {
        case .milliliters:  return 1
        case .fluidOunces:  return 29.5735
        }
    }

    /// Incremento usado em steppers e botões de ajuste.
    var step: Double {
        switch self {
        case .milliliters:  return 50
        case .fluidOunces:  return 2
        }
    }

    func value(fromMilliliters milliliters: Double) -> Double {
        milliliters / millilitersPerUnit
    }

    func milliliters(from value: Double) -> Double {
        value * millilitersPerUnit
    }

    /// Texto pronto para exibição, ex.: "1.750 ml" ou "59,2 oz".
    func format(_ milliliters: Double, includeUnit: Bool = true) -> String {
        let converted = value(fromMilliliters: milliliters)
        let number: String
        switch self {
        case .milliliters:
            number = converted.rounded().formatted(.number.precision(.fractionLength(0)))
        case .fluidOunces:
            number = converted.formatted(.number.precision(.fractionLength(1)))
        }
        return includeUnit ? "\(number) \(shortName)" : number
    }

    /// Converte um valor digitado (na unidade atual) em texto editável.
    func editableText(forMilliliters milliliters: Double) -> String {
        let converted = value(fromMilliliters: milliliters)
        switch self {
        case .milliliters:  return String(Int(converted.rounded()))
        case .fluidOunces:  return String(format: "%.1f", converted)
        }
    }
}

// MARK: - Registro de consumo

struct DrinkEntry: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var date: Date
    var amountML: Double

    init(id: UUID = UUID(), date: Date = Date(), amountML: Double) {
        self.id = id
        self.date = date
        self.amountML = amountML
    }
}

/// Total consumido em um dia (usado no histórico e no gráfico).
struct DayTotal: Identifiable, Equatable, Sendable {
    var id: Date { date }
    let date: Date
    let totalML: Double
}

// MARK: - Ícones

enum DrinkSymbol {
    /// Escolhe um símbolo (SF Symbols) coerente com o tamanho do gole.
    static func name(forML milliliters: Double) -> String {
        switch milliliters {
        case ..<250:  return "cup.and.saucer.fill"
        case ..<400:  return "takeoutbag.and.cup.and.straw.fill"
        case ..<600:  return "waterbottle.fill"
        default:      return "drop.fill"
        }
    }
}

// MARK: - Ajustes

struct AppSettings: Codable, Equatable, Sendable {
    var dailyGoalML: Double = 2000
    var unit: VolumeUnit = .milliliters
    var quickAmountsML: [Double] = [200, 350, 500, 750]
    var remindersEnabled: Bool = false
    var reminderIntervalHours: Int = 2
    var reminderStartHour: Int = 8
    var reminderEndHour: Int = 22

    init() {}

    /// Decodificação tolerante: se uma versão futura adicionar campos,
    /// os ajustes antigos continuam carregando sem erro.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let padrao = AppSettings()
        dailyGoalML = try container.decodeIfPresent(Double.self, forKey: .dailyGoalML) ?? padrao.dailyGoalML
        unit = try container.decodeIfPresent(VolumeUnit.self, forKey: .unit) ?? padrao.unit
        quickAmountsML = try container.decodeIfPresent([Double].self, forKey: .quickAmountsML) ?? padrao.quickAmountsML
        remindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .remindersEnabled) ?? padrao.remindersEnabled
        reminderIntervalHours = try container.decodeIfPresent(Int.self, forKey: .reminderIntervalHours) ?? padrao.reminderIntervalHours
        reminderStartHour = try container.decodeIfPresent(Int.self, forKey: .reminderStartHour) ?? padrao.reminderStartHour
        reminderEndHour = try container.decodeIfPresent(Int.self, forKey: .reminderEndHour) ?? padrao.reminderEndHour
    }
}
