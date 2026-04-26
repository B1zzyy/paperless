import UIKit
import CoreHaptics

enum Haptics {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private static var engine: CHHapticEngine?
    private static var continuousPlayer: CHHapticAdvancedPatternPlayer?

    static func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        notificationGenerator.prepare()
        try? prepareEngineIfNeeded()
    }

    static func light() {
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    static func medium() {
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    static func success() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }

    static func startSoftContinuous(duration: TimeInterval) {
        let clampedDuration = max(0.05, duration)

        guard supportsCoreHaptics else {
            light()
            return
        }

        do {
            try prepareEngineIfNeeded()
            try continuousPlayer?.stop(atTime: CHHapticTimeImmediate)

            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.34),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.14)
                ],
                relativeTime: 0,
                duration: clampedDuration
            )

            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makeAdvancedPlayer(with: pattern)
            continuousPlayer = player
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Graceful fallback when engine/player creation fails.
            light()
        }
    }

    static func stopSoftContinuous() {
        try? continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        continuousPlayer = nil
    }

    private static func prepareEngineIfNeeded() throws {
        guard supportsCoreHaptics else { return }

        if engine == nil {
            engine = try CHHapticEngine()
            engine?.stoppedHandler = { _ in
                continuousPlayer = nil
            }
            engine?.resetHandler = {
                try? engine?.start()
            }
        }

        try engine?.start()
    }
}
