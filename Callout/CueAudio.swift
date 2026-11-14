import AVFoundation
import CalloutCore

/// Plays the cue sounds at exact host times on an `AVAudioEngine`.
///
/// Every cue is scheduled ahead of time against the host clock, so timing holds while the phone is
/// locked or another app is in front. The running engine keeps the app alive in the background
/// (the `audio` background mode). Voice and ticks share one player; the fanfare has its own so it can
/// overlap the next round's first cue.
final class CueAudio {
    private let engine = AVAudioEngine()
    private let voice = AVAudioPlayerNode()
    private let fanfare = AVAudioPlayerNode()
    private var buffers: [CueSound: [AVAudioPCMBuffer]] = [:]

    /// Called on the main actor when audio stops underneath a session: a call, Siri, or an engine reset.
    var onInterrupted: (() -> Void)?

    init() {
        let files: [CueSound: [String]] = [
            .thirty: ["thirty"], .fifteen: ["fifteen"], .ten: ["ten"],
            .five: ["five"], .four: ["four"], .three: ["three"], .two: ["two"], .one: ["one"],
            .tick: ["tick"], .fanfare: ["fanfare1", "fanfare2"],
        ]
        for (sound, names) in files {
            buffers[sound] = names.compactMap(Self.load)
        }
        let format = buffers[.tick]?.first?.format
        engine.attach(voice)
        engine.attach(fanfare)
        engine.connect(voice, to: engine.mainMixerNode, format: format)
        engine.connect(fanfare, to: engine.mainMixerNode, format: format)
        observe()
    }

    private static func load(_ name: String) -> AVAudioPCMBuffer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav"),
              let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
        else { return nil }
        try? file.read(into: buffer)
        return buffer
    }

    /// Activates playback that ignores the silent switch and mixes over the user's music.
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        if !engine.isRunning {
            engine.prepare()
            try engine.start()
        }
        voice.play()
        fanfare.play()
    }

    /// Queues `cues`, whose offsets count from host time `sessionStart`.
    func schedule(_ cues: [Cue], sessionStart: UInt64) {
        for cue in cues {
            guard let buffer = buffers[cue.sound]?.randomElement() else { continue }
            let when = AVAudioTime(hostTime: sessionStart + AVAudioTime.hostTime(forSeconds: cue.offset))
            let node = cue.sound == .fanfare ? fanfare : voice
            node.scheduleBuffer(buffer, at: when, options: [], completionHandler: nil)
        }
    }

    /// Drops every queued cue. Anything playing stops at once.
    func clear() {
        voice.stop()
        fanfare.stop()
    }

    /// Stops the engine and gives the audio session back, unducking other apps.
    func shutDown() {
        clear()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func observe() {
        let center = NotificationCenter.default
        Task { [weak self] in
            for await note in center.notifications(named: AVAudioSession.interruptionNotification) {
                guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      AVAudioSession.InterruptionType(rawValue: raw) == .began else { continue }
                self?.onInterrupted?()
            }
        }
        Task { [weak self, engine] in
            for await _ in center.notifications(named: .AVAudioEngineConfigurationChange, object: engine) {
                self?.onInterrupted?()
            }
        }
    }
}
