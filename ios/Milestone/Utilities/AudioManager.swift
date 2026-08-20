import Foundation
import AVFoundation

public enum LuxuryAudioEffect: String {
    case missionStart = "mission_start"
    case missionComplete = "mission_complete"
    case pomodoroStart = "pomodoro_start"
    case focusComplete = "focus_complete"
    case breakComplete = "break_complete"
}

@MainActor
public final class AudioManager {
    public static let shared = AudioManager()

    private var players: [LuxuryAudioEffect: AVAudioPlayer] = [:]

    private init() {
        configureAudioSession()
        preloadSounds()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set AVAudioSession category: \(error.localizedDescription)")
        }
    }

    private func preloadSounds() {
        let effects: [LuxuryAudioEffect] = [
            .missionStart,
            .missionComplete,
            .pomodoroStart,
            .focusComplete,
            .breakComplete
        ]

        for effect in effects {
            if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "caf") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    players[effect] = player
                } catch {
                    print("Failed to load sound \(effect.rawValue): \(error.localizedDescription)")
                }
            }
        }
    }

    public func play(_ effect: LuxuryAudioEffect) {
        let isEnabled = UserDefaults.standard.object(forKey: "milestone:soundEnabled") as? Bool ?? true
        guard isEnabled else { return }

        if let player = players[effect] {
            if player.isPlaying {
                player.currentTime = 0
            }
            player.play()
        }
    }
}
