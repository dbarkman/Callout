import AVFoundation
import CalloutCore
import Observation
import UIKit

/// Runs one-minute rounds against the host clock and keeps the audio queue a round ahead.
@Observable
final class TimerModel {
    enum State { case idle, running, paused, finished }

    private(set) var state: State = .idle
    var repeats: Bool {
        didSet { UserDefaults.standard.set(repeats, forKey: "repeats") }
    }

    let plan = IntervalPlan(roundSeconds: 60)

    @ObservationIgnored private let audio = CueAudio()
    /// Host time of elapsed zero while running.
    @ObservationIgnored private var sessionStart: UInt64 = 0
    @ObservationIgnored private var pausedElapsed: Double = 0
    @ObservationIgnored private var scheduledThrough = -1
    @ObservationIgnored private var watcher: Task<Void, Never>?

    init() {
        repeats = UserDefaults.standard.object(forKey: "repeats") as? Bool ?? false
        audio.onInterrupted = { [weak self] in self?.handleInterruption() }
    }

    /// Seconds since the session started, frozen while paused.
    func elapsed(atHost host: UInt64 = mach_absolute_time()) -> Double {
        switch state {
        case .idle: 0
        case .paused: pausedElapsed
        case .finished: Double(plan.roundSeconds)
        case .running: host >= sessionStart ? AVAudioTime.seconds(forHostTime: host - sessionStart) : 0
        }
    }

    func status() -> IntervalStatus {
        plan.status(at: elapsed(), repeats: repeats)
    }

    func start() {
        pausedElapsed = 0
        run(from: 0)
    }

    func pause() {
        guard state == .running else { return }
        pausedElapsed = elapsed()
        watcher?.cancel()
        audio.clear()
        state = .paused
        UIApplication.shared.isIdleTimerDisabled = false
    }

    func resume() {
        guard state == .paused else { return }
        run(from: pausedElapsed)
    }

    func reset() {
        watcher?.cancel()
        audio.shutDown()
        pausedElapsed = 0
        state = .idle
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func run(from elapsed: Double) {
        do {
            try audio.start()
        } catch {
            // Without audio the callouts can't play; stay put rather than run silently.
            return
        }
        // A short lead lets the first cue be queued before its time arrives.
        let lead = AVAudioTime.hostTime(forSeconds: 0.15)
        sessionStart = mach_absolute_time() + lead - AVAudioTime.hostTime(forSeconds: elapsed)
        state = .running
        UIApplication.shared.isIdleTimerDisabled = true

        let current = plan.roundIndex(at: elapsed)
        scheduledThrough = repeats ? current + 1 : current
        audio.schedule(plan.cues(from: elapsed, throughRound: scheduledThrough), sessionStart: sessionStart)
        watch()
    }

    /// Wakes at each round boundary: queues another round when repeating, or finishes.
    private func watch() {
        watcher?.cancel()
        watcher = Task { [weak self] in
            while let self, !Task.isCancelled {
                let now = self.elapsed()
                let boundary = Double(self.plan.roundIndex(at: now) + 1) * Double(self.plan.roundSeconds)
                try? await Task.sleep(for: .seconds(boundary - now + 0.05))
                guard !Task.isCancelled, self.state == .running else { return }
                if self.repeats {
                    self.scheduledThrough += 1
                    self.audio.schedule(self.plan.cues(forRound: self.scheduledThrough), sessionStart: self.sessionStart)
                } else {
                    self.finish()
                    return
                }
            }
        }
    }

    private func finish() {
        state = .finished
        UIApplication.shared.isIdleTimerDisabled = false
        // Let the cheer ring out before releasing the audio session.
        watcher = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4.5))
            guard !Task.isCancelled, let self, self.state == .finished else { return }
            self.audio.shutDown()
        }
    }

    private func handleInterruption() {
        guard state == .running else { return }
        pause()
    }
}
