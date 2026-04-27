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

struct ReceiptPaperCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.98),
                                Color(red: 0.982, green: 0.980, blue: 0.972),
                                Color.white.opacity(0.97)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay {
                        // Texture stays intentionally subtle for an Apple-clean paper feel.
                        Image("ReceiptPaperTexture")
                            .resizable()
                            .scaledToFill()
                            .blendMode(.multiply)
                            .opacity(0.34)
                            .saturation(0.97)
                            .contrast(1.14)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                    .overlay {
                        // Secondary grain pass for more tactile paper realism.
                        Image("ReceiptPaperTexture")
                            .resizable()
                            .scaledToFill()
                            .blendMode(.softLight)
                            .opacity(0.22)
                            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                    .overlay {
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.42),
                                .clear,
                                Color.black.opacity(0.08)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .inset(by: 1)
                            .stroke(Color.black.opacity(0.05), lineWidth: 1)
                            .blur(radius: 1.3)
                            .mask(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [.black, .clear, .black.opacity(0.75)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.70), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.black.opacity(0.07), lineWidth: 0.7)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
    }
}

struct LiquidIconButton: ViewModifier {
    let size: CGFloat

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .frame(width: size, height: size)
                .glassEffect(.regular.tint(.white.opacity(0.20)).interactive(), in: .circle)
        } else {
            content
                .frame(width: size, height: size)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.42), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
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

    func receiptPaperCard() -> some View {
        modifier(ReceiptPaperCard())
    }

    func liquidIconButton(size: CGFloat = 34) -> some View {
        modifier(LiquidIconButton(size: size))
    }
}
