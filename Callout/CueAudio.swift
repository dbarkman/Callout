import AVFoundation
import CalloutCore

/// Plays the cue sounds at exact host times on an `AVAudioEngine`.
///
/// Every cue is scheduled ahead of time against the host clock, so timing holds while the phone is
/// locked or another app is in front. The running engine keeps the app alive in the background
/// (the `audio` background mode). Short cues alternate between two players, so a voice line that runs
/// a little long never delays the next one; the cheer has its own player so it can ring into the next round.
final class CueAudio {
    private let engine = AVAudioEngine()
    private let voices = [AVAudioPlayerNode(), AVAudioPlayerNode()]
    private let cheer = AVAudioPlayerNode()
    private var nextVoice = 0
    private var players: [AVAudioPlayerNode] { voices + [cheer] }
    private var buffers: [CueSound: [AVAudioPCMBuffer]] = [:]

    /// Called on the main actor when audio stops underneath a session: a call, Siri, or an engine reset.
    var onInterrupted: (() -> Void)?

    init() {
        let files: [CueSound: [String]] = [
            .chime: ["chime"], .thirty: ["thirty"], .fifteen: ["fifteen"], .ten: ["ten"],
            .five: ["five"], .four: ["four"], .three: ["three"], .two: ["two"], .one: ["one"],
            .tick: ["tick"], .cheer: ["cheer1", "cheer2", "cheer3"],
        ]
        for (sound, names) in files {
            buffers[sound] = names.compactMap(Self.load)
        }
        let format = buffers[.tick]?.first?.format
        for player in players {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
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
        players.forEach { $0.play() }
    }

    /// Queues `cues`, whose offsets count from host time `sessionStart`.
    func schedule(_ cues: [Cue], sessionStart: UInt64) {
        for cue in cues {
            guard let buffer = buffers[cue.sound]?.randomElement() else { continue }
            let when = AVAudioTime(hostTime: sessionStart + AVAudioTime.hostTime(forSeconds: cue.offset))
            let node: AVAudioPlayerNode
            if cue.sound == .cheer {
                node = cheer
            } else {
                node = voices[nextVoice]
                nextVoice = (nextVoice + 1) % voices.count
            }
            node.scheduleBuffer(buffer, at: when, options: [], completionHandler: nil)
        }
    }

    /// Drops every queued cue. Anything playing stops at once.
    func clear() {
        players.forEach { $0.stop() }
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
