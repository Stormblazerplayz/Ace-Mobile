import CoreMotion
import SwiftUI

/// Tilts the orb a little as you tilt the iPad, so it feels like a real ball.
/// Only runs while the orb is on screen, and not when Reduce Motion is on.
@MainActor
final class OrbMotion: ObservableObject {
    /// -1...1 left/right and forward/back, measured from how you were holding the iPad.
    @Published private(set) var tilt: CGSize = .zero

    private let manager = CMMotionManager()
    private var base: CMAcceleration?
    private var running = false

    func start() {
        guard !running, manager.isDeviceMotionAvailable else { return }
        running = true
        manager.deviceMotionUpdateInterval = 1 / 30
        base = nil
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let g = motion?.gravity else { return }
            MainActor.assumeIsolated { self?.update(g) }
        }
    }

    func stop() {
        guard running else { return }
        running = false
        manager.stopDeviceMotionUpdates()
        base = nil
        tilt = .zero
    }

    private func update(_ g: CMAcceleration) {
        // Slowly follow how you hold the iPad, so only quick tilts move the orb.
        var b = base ?? g
        b.x += (g.x - b.x) * 0.01
        b.y += (g.y - b.y) * 0.01
        base = b
        let target = CGSize(width: Self.clamp((g.x - b.x) * 3), height: Self.clamp((g.y - b.y) * 3))
        // Smooth it so the orb glides instead of shaking.
        tilt = CGSize(width: tilt.width + (target.width - tilt.width) * 0.2,
                      height: tilt.height + (target.height - tilt.height) * 0.2)
    }

    nonisolated static func clamp(_ v: Double) -> Double { min(1, max(-1, v)) }
}
