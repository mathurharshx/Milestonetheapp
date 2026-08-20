import Foundation
import AudioToolbox
import AVFoundation

let outputDir = "/Users/harshmathur/Milestone experiments/ios/Milestone/Resources/Audio"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

func generateAudioFile(filename: String, generator: (Int, Double) -> Float, duration: Double, sampleRate: Double = 44100.0) {
    let numSamples = Int(duration * sampleRate)
    var samples = [Float](repeating: 0, count: numSamples)
    
    for i in 0..<numSamples {
        let t = Double(i) / sampleRate
        samples[i] = generator(i, t)
    }
    
    let fileURL = URL(fileURLWithPath: "\(outputDir)/\(filename)")
    
    var asbd = AudioStreamBasicDescription(
        mSampleRate: sampleRate,
        mFormatID: kAudioFormatLinearPCM,
        mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
        mBytesPerPacket: 4,
        mFramesPerPacket: 1,
        mBytesPerFrame: 4,
        mChannelsPerFrame: 1,
        mBitsPerChannel: 32,
        mReserved: 0
    )
    
    var audioFile: ExtAudioFileRef?
    let status = ExtAudioFileCreateWithURL(
        fileURL as CFURL,
        kAudioFileCAFType,
        &asbd,
        nil,
        AudioFileFlags.eraseFile.rawValue,
        &audioFile
    )
    
    guard status == noErr, let file = audioFile else {
        print("Failed to create audio file: \(filename), status: \(status)")
        return
    }
    
    var buffer = AudioBuffer(
        mNumberChannels: 1,
        mDataByteSize: UInt32(numSamples * 4),
        mData: &samples
    )
    var bufferList = AudioBufferList(
        mNumberBuffers: 1,
        mBuffers: buffer
    )
    
    ExtAudioFileWrite(file, UInt32(numSamples), &bufferList)
    ExtAudioFileDispose(file)
    print("Generated luxury audio: \(filename) (\(String(format: "%.2f", duration))s)")
}

// 1. Mission Start: Low-frequency 350Hz warm acoustic strike with exponential decay
generateAudioFile(filename: "mission_start.caf", generator: { i, t in
    let freq = 350.0 - (t * 80.0)
    let env = exp(-t * 8.0)
    let wave = sin(2.0 * .pi * freq * t) + 0.3 * sin(4.0 * .pi * freq * t)
    return Float(wave * env * 0.45)
}, duration: 0.45)

// 2. Mission Complete: Ascending 3-note luxury triad chord (C5=523.25Hz, E5=659.25Hz, G5=783.99Hz)
generateAudioFile(filename: "mission_complete.caf", generator: { i, t in
    let env = exp(-t * 3.5)
    let n1 = sin(2.0 * .pi * 523.25 * t)
    let n2 = t > 0.08 ? sin(2.0 * .pi * 659.25 * (t - 0.08)) * exp(-(t - 0.08) * 3.5) : 0
    let n3 = t > 0.16 ? sin(2.0 * .pi * 783.99 * (t - 0.16)) * exp(-(t - 0.16) * 3.5) : 0
    let wave = (n1 * 0.4 + n2 * 0.4 + n3 * 0.4)
    return Float(wave * env * 0.35)
}, duration: 0.85)

// 3. Pomodoro Start: Soft 440Hz tactile resonator ping
generateAudioFile(filename: "pomodoro_start.caf", generator: { i, t in
    let freq = 440.0
    let env = exp(-t * 12.0)
    let wave = sin(2.0 * .pi * freq * t) + 0.2 * sin(2.0 * .pi * freq * 2.0 * t)
    return Float(wave * env * 0.35)
}, duration: 0.35)

// 4. Focus Complete (Break Start): 528Hz Solfeggio singing bowl chime with 1.8s peaceful decay
generateAudioFile(filename: "focus_complete.caf", generator: { i, t in
    let freq = 528.0
    let env = exp(-t * 2.2)
    let wave = sin(2.0 * .pi * freq * t) + 0.25 * sin(2.0 * .pi * (freq * 1.5) * t) + 0.15 * sin(2.0 * .pi * (freq * 2.0) * t)
    return Float(wave * env * 0.30)
}, duration: 1.6)

// 5. Break Complete (Focus Start): Two-tone rising chime (440Hz -> 660Hz)
generateAudioFile(filename: "break_complete.caf", generator: { i, t in
    let env1 = exp(-t * 6.0)
    let env2 = t > 0.12 ? exp(-(t - 0.12) * 5.0) : 0
    let n1 = sin(2.0 * .pi * 440.0 * t) * env1
    let n2 = t > 0.12 ? sin(2.0 * .pi * 660.0 * (t - 0.12)) * env2 : 0
    let wave = (n1 * 0.4 + n2 * 0.45)
    return Float(wave * 0.35)
}, duration: 0.6)

