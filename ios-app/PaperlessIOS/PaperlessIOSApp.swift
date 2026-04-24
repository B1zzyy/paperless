    import SwiftUI
import UIKit

@main
struct PaperlessIOSApp: App {
    var body: some Scene {
        WindowGroup {
            RootLaunchView()
                .preferredColorScheme(.light)
        }
    }
}

private struct RootLaunchView: View {
    @State private var revealApp = false
    @State private var collapseSplash = false

    var body: some View {
        ZStack {
            ContentView()
                .opacity(revealApp ? 1 : 0)
                .animation(.easeOut(duration: 0.45), value: revealApp)

            SplashView(collapse: collapseSplash)
                .opacity(revealApp ? 0 : 1)
                .animation(.easeInOut(duration: 0.5), value: revealApp)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.55)) {
                    collapseSplash = true
                }
            }

            // Start revealing app before shrink finishes for seamless overlap.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
                withAnimation(.easeOut(duration: 0.45)) {
                    revealApp = true
                }
            }
        }
    }
}

private struct SplashView: View {
    let collapse: Bool

    var body: some View {
        GeometryReader { proxy in
            let diagonal = sqrt((proxy.size.width * proxy.size.width) + (proxy.size.height * proxy.size.height))
            let fullScreenScale = (diagonal / 200) * 1.1

            ZStack {
                Color(red: 0.34, green: 0.60, blue: 0.48)
                    .ignoresSafeArea()
                    .overlay {
                        VStack(spacing: 14) {
                            AppIconImage()
                                .frame(width: 94, height: 94)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)

                            Text("Paperless")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.95))
                        }
                        .scaleEffect(collapse ? 0.75 : 1)
                        .opacity(collapse ? 0.0 : 1.0)
                        .animation(.easeInOut(duration: 0.35), value: collapse)
                    }
                    .mask(
                        Circle()
                            .scaleEffect(collapse ? 0.03 : fullScreenScale)
                            .frame(width: 200, height: 200)
                    )
                    .animation(.easeInOut(duration: 0.55), value: collapse)
            }
        }
    }
}

private struct AppIconImage: View {
    var body: some View {
        if let image = Bundle.main.primaryAppIcon {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.18))
                .overlay(
                    Image(systemName: "app.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.92))
                )
        }
    }
}

private extension Bundle {
    var primaryAppIcon: UIImage? {
        guard
            let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String],
            let iconName = files.last,
            let image = UIImage(named: iconName)
        else {
            return nil
        }
        return image
    }
}
