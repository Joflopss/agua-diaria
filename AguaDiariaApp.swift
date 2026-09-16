//
//  AguaDiariaApp.swift
//  Água Diária
//
//  Ponto de entrada. Deployment target: iOS 16.0 (roda igual no iOS 17).
//

import SwiftUI

@main
struct AguaDiariaApp: App {
    @StateObject private var store = WaterStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .tint(Theme.accent)
        }
        .onChange(of: scenePhase) { phase in
            // Garante que nada se perca quando o app sai da tela.
            if phase != .active { store.save() }
        }
    }
}

struct RootView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Hoje", systemImage: "drop.fill") }

            HistoryView()
                .tabItem { Label("Histórico", systemImage: "chart.bar.fill") }

            SettingsView()
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
        }
    }
}

#if DEBUG
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView().environmentObject(WaterStore())
    }
}
#endif
