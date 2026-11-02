import AVFoundation
import UIKit

@MainActor
final class FeedbackService {
    static let shared = FeedbackService()

    private var tonePlayers: [AVAudioPlayer] = []
    private var enginePlayer: AVAudioPlayer?
    private var ambiencePlayer: AVAudioPlayer?
    private var activeBiome: Int?

    private init() {}

    func hit(audio: Bool, haptics: Bool) {
        if audio { tone(frequency: 92, duration: 0.12, amplitude: 0.34) }
        if haptics { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    }

    func pickup(audio: Bool, haptics: Bool) {
        if audio { tone(frequency: 740, duration: 0.10, amplitude: 0.18) }
        if haptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    }

    func updateEngine(speed: CGFloat, audio: Bool, biome: Int) {
        guard audio else {
            stopEngine()
            return
        }
        if enginePlayer == nil, let player = try? AVAudioPlayer(data: makeWave(frequencies: [48, 96, 144], duration: 0.5, amplitude: 0.18, loop: true)) {
            player.numberOfLoops = -1
            player.enableRate = true
            player.volume = 0.10
            player.prepareToPlay()
            player.play()
            enginePlayer = player
        }
        if let enginePlayer {
            enginePlayer.rate = Float(0.72 + min(1.15, max(0, Double(speed) / 2600)))
            enginePlayer.volume = Float(0.025 + min(0.09, Double(speed) / 18000))
            if !enginePlayer.isPlaying { enginePlayer.play() }
        }
        if activeBiome != biome || ambiencePlayer == nil {
            ambiencePlayer?.stop()
            activeBiome = biome
            let roots: [Double] = [55, 58, 62, 65, 69, 73, 78, 82, 87, 92]
            let root = roots[min(max(biome, 0), roots.count - 1)]
            let notes = [root, root * 1.5, root * 2.0]
            if let player = try? AVAudioPlayer(data: makeWave(frequencies: notes, duration: 4, amplitude: 0.075, loop: true)) {
                player.numberOfLoops = -1
                player.volume = 0.16
                player.prepareToPlay()
                player.play()
                ambiencePlayer = player
            }
        }
    }

    func stopEngine() {
        enginePlayer?.stop()
        ambiencePlayer?.stop()
        enginePlayer = nil
        ambiencePlayer = nil
        activeBiome = nil
    }

    private func tone(frequency: Double, duration: Double, amplitude: Float) {
        tonePlayers.removeAll { !$0.isPlaying }
        guard let player = try? AVAudioPlayer(data: makeWave(frequencies: [frequency], duration: duration, amplitude: amplitude, loop: false)) else { return }
        player.volume = 1
        player.prepareToPlay()
        player.play()
        tonePlayers.append(player)
    }

    private func makeWave(frequencies: [Double], duration: Double, amplitude: Float, loop: Bool) -> Data {
        let sampleRate: UInt32 = 44_100
        let frameCount = Int(Double(sampleRate) * duration)
        var samples = Data()
        samples.reserveCapacity(frameCount * 2)

        for frame in 0..<frameCount {
            let time = Double(frame) / Double(sampleRate)
            var value = 0.0
            for frequency in frequencies {
                value += sin(2 * Double.pi * frequency * time)
            }
            value /= Double(max(1, frequencies.count))
            let envelope: Double
            if loop {
                envelope = 0.72 + 0.28 * sin(2 * Double.pi * 0.25 * time)
            } else {
                let progress = Double(frame) / Double(max(1, frameCount))
                envelope = min(1, progress * 16) * max(0, 1 - progress)
            }
            let sample = max(-1, min(1, value * Double(amplitude) * envelope))
            var pcm = Int16(sample * 32_000).littleEndian
            withUnsafeBytes(of: &pcm) { samples.append(contentsOf: $0) }
        }

        var wave = Data()
        wave.append(contentsOf: "RIFF".utf8)
        appendLE(UInt32(36 + samples.count), to: &wave)
        wave.append(contentsOf: "WAVEfmt ".utf8)
        appendLE(UInt32(16), to: &wave)
        appendLE(UInt16(1), to: &wave)
        appendLE(UInt16(1), to: &wave)
        appendLE(sampleRate, to: &wave)
        appendLE(sampleRate * 2, to: &wave)
        appendLE(UInt16(2), to: &wave)
        appendLE(UInt16(16), to: &wave)
        wave.append(contentsOf: "data".utf8)
        appendLE(UInt32(samples.count), to: &wave)
        wave.append(samples)
        return wave
    }

    private func appendLE<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
}
