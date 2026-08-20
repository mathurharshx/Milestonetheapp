import Foundation
import AudioToolbox
import AVFoundation

let outputDir = "/Users/harshmathur/Milestone experiments/ios/Milestone/Resources/Audio"

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
    print("Updated mission_start.caf (0.50s)")
}

// Crisp, inspiring crystal glass chime + warm sub-tone (880Hz + 440Hz harmonic)
generateAudioFile(filename: "mission_start.caf", generator: { i, t in
    let env = exp(-t * 9.0)
    let attack = min(1.0, t / 0.005) // 5ms attack for crisp transient click
    let f1 = 880.0 // Crystal Ping
    let f2 = 440.0 // Warm Body
    let wave1 = sin(2.0 * .pi * f1 * t)
    let wave2 = sin(2.0 * .pi * f2 * t) * 0.5
    let wave3 = sin(2.0 * .pi * (f1 * 1.5) * t) * 0.2
    return Float((wave1 + wave2 + wave3) * attack * env * 0.38)
}, duration: 0.50)

