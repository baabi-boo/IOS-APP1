import AVFoundation

/// Dewy's little sound effects. They mix with other audio and respect the silent switch.
@MainActor
enum SoundFX {
    enum Effect: String {
        case pour, goal, pop
    }

    /// Mirrors the user's setting.
    static var isEnabled = true

    private static var players: [Effect: AVAudioPlayer] = [:]
    private static var isConfigured = false

    static func play(_ effect: Effect, volume: Float = 0.55) {
        guard isEnabled, !LaunchOptions.isDemo else { return }
        if !isConfigured {
            try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            isConfigured = true
        }
        if players[effect] == nil {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav") else { return }
            players[effect] = try? AVAudioPlayer(contentsOf: url)
            players[effect]?.prepareToPlay()
        }
        guard let player = players[effect] else { return }
        player.volume = volume
        player.currentTime = 0
        player.play()
    }
}
