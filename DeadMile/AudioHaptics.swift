import AVFoundation
import UIKit

@MainActor
final class FeedbackService {
    static let shared = FeedbackService()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var isReady = false

    private init() {}

    func hit(audio: Bool, haptics: Bool) {
        if audio { tone(frequency: 92, duration: 0.12, amplitude: 0.34) }
        if haptics { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    }

    func pickup(audio: Bool, haptics: Bool) {
        if audio { tone(frequency: 740, duration: 0.10, amplitude: 0.18) }
        if haptics { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    }

    private func tone(frequency: Double, duration: Double, amplitude: Float) {
        if !isReady {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            do {
                try engine.start()
                isReady = true
            } catch {
                return
            }
        }
        let count = AVAudioFrameCount(max(1, Int(format.sampleRate * duration)))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count),
              let channel = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = count
        for frame in 0..<Int(count) {
            let progress = Float(frame) / Float(count)
            let envelope = min(1, progress * 16) * (1 - progress)
            let wave = sin(2 * Double.pi * frequency * Double(frame) / format.sampleRate)
            channel[frame] = Float(wave) * amplitude * envelope
        }
        player.scheduleBuffer(buffer)
        if !player.isPlaying { player.play() }
    }
}
