//
//  NotificationManager.swift
//  Água Diária
//
//  Lembretes locais e repetitivos. Não precisa de chave no Info.plist
//  nem de capability — só da permissão do usuário.
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

    /// Pede autorização e devolve o resultado na thread principal.
    static func requestAuthorization(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// Remove os lembretes antigos e reagenda conforme os ajustes atuais.
    static func refresh(with settings: AppSettings) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let ids = requests.map { $0.identifier }.filter { $0.hasPrefix(identifierPrefix) }
            if !ids.isEmpty {
                center.removePendingNotificationRequests(withIdentifiers: ids)
            }
            guard settings.remindersEnabled else { return }
            schedule(with: settings)
        }
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
