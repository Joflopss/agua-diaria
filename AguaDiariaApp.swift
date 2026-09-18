//
//  AguaDiariaApp.swift
//  Água Diária
//
//  Ponto de entrada. Deployment target: iOS 17.0 (testado até iOS 26/27).
//  Usa @Observable + @Environment (padrão moderno) no lugar de
//  ObservableObject/@EnvironmentObject.
//

import SwiftUI

@main
struct AguaDiariaApp: App {
    @State private var store = WaterStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .tint(Theme.accent)
        }
        .onChange(of: scenePhase) {
            // Garante que nada se perca quando o app sai da tela.
            if scenePhase != .active { store.save() }
        }
    }
}

struct RootView: View {
    var body: some View {
        // No iOS 26/27, o TabView passa a usar automaticamente a barra em
        // Liquid Glass (translúcida, com "lente" sobre o conteúdo) assim que
        // o app é compilado com o SDK novo — não é preciso nenhum código
        // extra para isso.
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

#Preview {
    RootView()
        .environment(WaterStore())
}
