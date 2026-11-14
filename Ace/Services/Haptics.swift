import CoreHaptics
import UIKit

/// Little taps that match the sounds. iPads have no vibration motor, so this only
/// does something on an iPhone. It's quietly skipped on an iPad.
@MainActor
final class Haptics {
    static let shared = Haptics()

    enum Kind { case pop, blink, success, alert, tick, wake }

    var enabled = true
    private var engine: CHHapticEngine?
    private let supported = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private init() {
        guard supported else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in
            Task { @MainActor in try? self?.engine?.start() }
        }
        engine?.stoppedHandler = { _ in }
        try? engine?.start()
    }

    func play(_ kind: Kind) {
        guard enabled, supported, let engine else { return }
        let events: [CHHapticEvent]
        switch kind {
        case .pop:
            events = [tap(0, 0.6, 0.7), tap(0.11, 0.8, 0.8)]
        case .blink:
            events = [tap(0, 0.3, 0.9)]
        case .tick:
            events = [tap(0, 0.25, 1)]
        case .success:
            events = [tap(0, 0.5, 0.4), tap(0.08, 0.7, 0.6), tap(0.16, 0.9, 0.8)]
        case .alert:
            events = [tap(0, 1, 0.5), tap(0.18, 0.8, 0.3)]
        case .wake:
            events = [
                CHHapticEvent(eventType: .hapticContinuous, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
                ], relativeTime: 0, duration: 0.35),
                tap(0.4, 0.7, 0.7),
            ]
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Haptics are a bonus. Ignore failures.
        }
    }

    private func tap(_ t: TimeInterval, _ intensity: Float, _ sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ], relativeTime: t)
    }
}
