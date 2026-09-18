//
//  NotificationManager.swift
//  Água Diária
//
//  Lembretes locais e repetitivos. Não precisa de chave no Info.plist
//  nem de capability — só da permissão do usuário.
//
//  Reescrito com async/await (em vez de completion handlers) para ficar
//  em conformidade com a checagem estrita de concorrência do Swift 6.
//

import Foundation
import UserNotifications

enum NotificationManager {

    private static let identifierPrefix = "hidratacao."

    private static let messages = [
        "Um copo agora ajuda a fechar a meta do dia.",
        "Pausa rápida: beba um pouco de água.",
        "Seu corpo agradece mais um gole.",
        "Hora de encher a garrafa de novo.",
        "Beba água e registre no app."
    ]

    /// Pede autorização ao usuário e devolve se foi concedida.
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    /// Remove os lembretes antigos e reagenda conforme os ajustes atuais.
    static func refresh(with settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let ids = requests.map { $0.identifier }.filter { $0.hasPrefix(identifierPrefix) }
        if !ids.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
        guard settings.remindersEnabled else { return }
        schedule(with: settings)
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Privado

    private static func schedule(with settings: AppSettings) {
        let center = UNUserNotificationCenter.current()
        let interval = max(1, settings.reminderIntervalHours)
        let start = min(settings.reminderStartHour, settings.reminderEndHour)
        let end = max(settings.reminderStartHour, settings.reminderEndHour)

        var hour = start
        var index = 0

        while hour <= end {
            let content = UNMutableNotificationContent()
            content.title = "Hora de beber água"
            content.body = messages[index % messages.count]
            content.sound = .default

            var components = DateComponents()
            components.hour = hour
            components.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(identifierPrefix)\(hour)",
                content: content,
                trigger: trigger
            )
            center.add(request)

            hour += interval
            index += 1
        }
    }
}
