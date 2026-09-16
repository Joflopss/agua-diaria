//
//  Components.swift
//  Água Diária
//
//  Peças visuais reutilizadas pelas telas.
//

import SwiftUI
import UIKit

// MARK: - Tema

enum Theme {
    static let accent = Color(red: 0.11, green: 0.52, blue: 0.93)
    static let accentLight = Color(red: 0.38, green: 0.80, blue: 0.98)

    static var ringGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [accentLight, accent, accentLight]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360)
        )
    }
}

// MARK: - Retorno tátil

enum Haptics {
    enum Kind { case light, success }

    static func play(_ kind: Kind) {
        switch kind {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Anel de progresso

struct WaterRingView: View {
    var progress: Double          // 1.0 = meta batida
    var centerValue: String
    var centerUnit: String
    var caption: String

    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.accent.opacity(0.15),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round))

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(Theme.ringGradient,
                        style: StrokeStyle(lineWidth: 22, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.45), value: clamped)

            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(centerValue)
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(centerUnit)
                        .font(.title3.weight(.medium))
                        .foregroundColor(.secondary)
                }
                Text(caption)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
        }
        .frame(width: 216, height: 216)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(centerValue) \(centerUnit), \(caption)")
    }
}

// MARK: - Botão de adição rápida

struct QuickAddButton: View {
    let label: String
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.title3)
                Text(label)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.accent.opacity(0.12))
            )
            .foregroundColor(Theme.accent)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Cartão de estatística

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Entrada de um valor avulso

struct AmountInputSheet: View {
    let title: String
    let unit: VolumeUnit
    let confirmTitle: String
    var initialML: Double = 0
    let onConfirm: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    @FocusState private var focused: Bool

    private var typedValue: Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var amountML: Double { unit.milliliters(from: typedValue) }

    private var steps: [Double] { [unit.step, unit.step * 2, unit.step * 5] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    TextField("0", text: $text)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .frame(maxWidth: 200)
                        .focused($focused)
                    Text(unit.shortName)
                        .font(.title2.weight(.medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)

                HStack(spacing: 12) {
                    ForEach(steps, id: \.self) { step in
                        Button {
                            text = format(typedValue + step)
                        } label: {
                            Text("+\(format(step))")
                                .frame(minWidth: 52)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Button(confirmTitle) {
                    guard amountML > 0 else { return }
                    onConfirm(amountML)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(amountML <= 0)

                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear {
                if initialML > 0 { text = unit.editableText(forMilliliters: initialML) }
                focused = true
            }
        }
        .presentationDetents([.medium])
    }

    private func format(_ value: Double) -> String {
        switch unit {
        case .milliliters:  return String(Int(value.rounded()))
        case .fluidOunces:  return String(format: "%.1f", value)
        }
    }
}
