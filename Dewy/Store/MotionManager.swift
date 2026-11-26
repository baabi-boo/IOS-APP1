import CoreMotion
import SwiftUI
import UIKit

/// Feeds the phone's tilt into Dewy's liquid. A damped spring chases the device's roll, so the
/// water leans, overshoots a little and settles, and a shake makes the surface choppy.
/// Runs only while the app is active and never in screenshots or with Reduce Motion.
@MainActor
final class MotionManager {
    let slosh = SloshSource()

    private let motion = CMMotionManager()
    private var velocity: Double = 0
    private var lastUpdate: TimeInterval?

    func start() {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive,
              !LaunchOptions.isDemo, !UIAccessibility.isReduceMotionEnabled else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            MainActor.assumeIsolated {
                self?.step(with: data)
            }
        }
    }

    func stop() {
        motion.stopDeviceMotionUpdates()
        lastUpdate = nil
        velocity = 0
        slosh.angle = 0
        slosh.energy = 0
    }

    private func step(with data: CMDeviceMotion) {
        let now = data.timestamp
        let dt = min(max(now - (lastUpdate ?? now - 1.0 / 60.0), 1.0 / 240.0), 1.0 / 20.0)
        lastUpdate = now

        // The liquid stays level with the world, so on screen it leans against the phone's roll.
        let roll = atan2(data.gravity.x, -data.gravity.y)
        let target = max(min(-roll * 0.8, 0.5), -0.5)

        // Damped spring: stiffness k, damping c.
        let k = 38.0
        let c = 5.5
        velocity += ((target - slosh.angle) * k - velocity * c) * dt
        slosh.angle += velocity * dt

        // Shakes add choppiness that fades out.
        let jolt = abs(data.userAcceleration.x) + abs(data.userAcceleration.y) * 0.6
        slosh.energy = min(max(slosh.energy * (1 - dt * 1.8), min(jolt * 0.9, 1)), 1)
    }
}
