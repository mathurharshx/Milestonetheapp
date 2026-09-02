import Foundation
import AVFoundation
import Observation

public enum SoundscapeType: String, CaseIterable, Identifiable {
    case brownNoise = "Brown Noise"
    case gammaFocus = "40Hz Gamma Focus"
    case off = "None"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .brownNoise: return "waveform.path"
        case .gammaFocus: return "brain.head.profile"
        case .off: return "speaker.slash"
        }
    }

    public var subtitle: String {
        switch self {
        case .brownNoise: return "Deep low-frequency roar to silence racing thoughts."
        case .gammaFocus: return "40Hz neural entrainment for deep concentration."
        case .off: return "Silent focus mode."
        }
    }
}

@MainActor
@Observable
public final class SoundscapeManager {
    public static let shared = SoundscapeManager()

    public var currentSoundscape: SoundscapeType = .off
    public var isPlaying: Bool = false
    public var volume: Float = 0.5 {
        didSet {
            mainMixer?.volume = volume
        }
    }

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var mainMixer: AVAudioMixerNode?

    public init() {}

    public func setSoundscape(_ type: SoundscapeType) {
        if type == .off {
            stop()
            return
        }

        currentSoundscape = type
        startProceduralAudio(type: type)
    }

    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            if currentSoundscape == .off {
                setSoundscape(.brownNoise)
            } else {
                startProceduralAudio(type: currentSoundscape)
            }
        }
    }

    public func pause() {
        audioEngine?.pause()
        isPlaying = false
    }

    public func stop() {
        audioEngine?.stop()
        audioEngine = nil
        sourceNode = nil
        currentSoundscape = .off
        isPlaying = false
    }

    // ── Procedural Real-Time Audio Synthesis ──
    private func startProceduralAudio(type: SoundscapeType) {
        // Stop any current engine
        audioEngine?.stop()

        let engine = AVAudioEngine()
        let mixer = engine.mainMixerNode
        mixer.volume = volume
        self.mainMixer = mixer

        // Configure Audio Session for Ambient background playback
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        let sampleRate: Double = 44100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!

        // Synthesizer State
        var lastBrownL: Float = 0.0
        var lastBrownR: Float = 0.0
        var phaseL: Double = 0.0
        var phaseR: Double = 0.0

        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let bufferL = ablPointer[0].mData?.assumingMemoryBound(to: Float.self)
            let bufferR = ablPointer.count > 1 ? ablPointer[1].mData?.assumingMemoryBound(to: Float.self) : bufferL

            let freqL = 200.0 // Base carrier frequency (Hz)
            let freqR = 240.0 // 40Hz binaural shift (Hz)

            for frame in 0..<Int(frameCount) {
                switch type {
                case .brownNoise:
                    // Procedural Brown Noise Filter: brown = (lastBrown + 0.02 * white) / 1.02
                    let whiteL = Float.random(in: -1.0...1.0)
                    let whiteR = Float.random(in: -1.0...1.0)

                    lastBrownL = (lastBrownL + (0.02 * whiteL)) / 1.02
                    lastBrownR = (lastBrownR + (0.02 * whiteR)) / 1.02

                    // Soft normalize and apply master headroom
                    bufferL?[frame] = lastBrownL * 3.5
                    bufferR?[frame] = lastBrownR * 3.5

                case .gammaFocus:
                    // 40Hz Binaural Sine Waves (Carrier + 40Hz offset)
                    let valL = Float(sin(phaseL)) * 0.15
                    let valR = Float(sin(phaseR)) * 0.15

                    phaseL += 2.0 * Double.pi * freqL / sampleRate
                    phaseR += 2.0 * Double.pi * freqR / sampleRate

                    if phaseL > 2.0 * Double.pi { phaseL -= 2.0 * Double.pi }
                    if phaseR > 2.0 * Double.pi { phaseR -= 2.0 * Double.pi }

                    // Mix subtle pink noise floor for warmth
                    let white = Float.random(in: -0.01...0.01)
                    bufferL?[frame] = valL + white
                    bufferR?[frame] = valR + white

                case .off:
                    bufferL?[frame] = 0.0
                    bufferR?[frame] = 0.0
                }
            }
            return noErr
        }

        self.sourceNode = node
        engine.attach(node)
        engine.connect(node, to: mixer, format: format)

        do {
            try engine.start()
            self.audioEngine = engine
            self.isPlaying = true
        } catch {
            print("Could not start audio engine: \(error)")
        }
    }
}
