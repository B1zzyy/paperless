import SwiftUI

enum AppColors {
    static let bg = Color(red: 0.97, green: 0.96, blue: 0.94)
    static let card = Color.white.opacity(0.72)
    static let text = Color(red: 0.13, green: 0.16, blue: 0.20)
    static let muted = Color(red: 0.45, green: 0.49, blue: 0.54)
    static let primary = Color(red: 0.34, green: 0.60, blue: 0.48)
    static let accent = Color(red: 0.87, green: 0.95, blue: 0.91)
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: 22))
        } else {
            content
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.35), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
    }
}

struct LiquidCapsule: ViewModifier {
    let tint: Color
    let interactive: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if interactive {
                content.glassEffect(.regular.tint(tint.opacity(0.8)).interactive(), in: .capsule)
            } else {
                content.glassEffect(.regular.tint(tint.opacity(0.75)), in: .capsule)
            }
        } else {
            content
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.40), lineWidth: 0.8)
                )
        }
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }

    func liquidCapsule(tint: Color = .clear, interactive: Bool = false) -> some View {
        modifier(LiquidCapsule(tint: tint, interactive: interactive))
    }
}
