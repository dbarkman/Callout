/// A sound the app plays at a fixed point in a round.
public enum CueSound: String, CaseIterable, Sendable {
    case chime, thirty, fifteen, ten, five, four, three, two, one, tick, cheer
}

/// One sound at an offset, in seconds, from the start of the session.
public struct Cue: Equatable, Sendable {
    public let offset: Double
    public let sound: CueSound

    public init(offset: Double, sound: CueSound) {
        self.offset = offset
        self.sound = sound
    }
}

/// How urgent the countdown looks, from the time left in the round.
public enum Phase: Int, Comparable, Sendable {
    case calm, warning, closing, final

    public static func < (a: Phase, b: Phase) -> Bool { a.rawValue < b.rawValue }

    public init(remaining: Double) {
        switch remaining {
        case ...5: self = .final
        case ...15: self = .closing
        case ...30: self = .warning
        default: self = .calm
        }
    }
}

/// Where a session stands at a moment.
public struct IntervalStatus: Equatable, Sendable {
    /// 1-based round number.
    public let round: Int
    /// Seconds left in the round, from the round length down to 0.
    public let remaining: Double
    /// Whole seconds to show: 60 at the start, 1 during the last second.
    public let displaySeconds: Int
    /// Fraction of the round still left, 1 at the start and 0 at the end.
    public let fractionLeft: Double
    public let phase: Phase
    public let finished: Bool
}

/// A countdown of `roundSeconds`, called out by voice and tones as it nears zero.
///
/// Time left → cue: 45 chime, 30 "Thirty seconds", 15 "Fifteen seconds", 13–11 ticks, 10 "Ten seconds", 9–6 ticks,
/// 5 to 1 counted aloud, 0 applause and cheering. With repeats on, the next round starts the moment the cheer plays.
public struct IntervalPlan: Equatable, Sendable {
    public static let minimumSeconds = 46

    public let roundSeconds: Int

    public init(roundSeconds: Int = 60) {
        self.roundSeconds = max(roundSeconds, Self.minimumSeconds)
    }

    private var length: Double { Double(roundSeconds) }

    /// The cues of one round, keyed by seconds left when each plays.
    static let cuesByTimeLeft: [(left: Int, sound: CueSound)] = [
        (45, .chime), (30, .thirty), (15, .fifteen),
        (13, .tick), (12, .tick), (11, .tick),
        (10, .ten),
        (9, .tick), (8, .tick), (7, .tick), (6, .tick),
        (5, .five), (4, .four), (3, .three), (2, .two), (1, .one),
        (0, .cheer),
    ]

    /// The cues of round `index` (0-based), as offsets from the start of the session.
    public func cues(forRound index: Int) -> [Cue] {
        let roundStart = Double(index) * length
        return Self.cuesByTimeLeft.map { Cue(offset: roundStart + length - Double($0.left), sound: $0.sound) }
    }

    /// The cues still to play from `elapsed` through round `lastRound` (0-based), in order.
    /// A cue exactly at `elapsed` is included.
    public func cues(from elapsed: Double, throughRound lastRound: Int) -> [Cue] {
        let first = max(0, roundIndex(at: elapsed) - 1)
        guard lastRound >= first else { return [] }
        return (first...lastRound).flatMap { cues(forRound: $0) }.filter { $0.offset >= elapsed }
    }

    /// The 0-based round that `elapsed` falls in, with repeats on.
    public func roundIndex(at elapsed: Double) -> Int {
        Int((max(0, elapsed) / length).rounded(.down))
    }

    /// The session's state `elapsed` seconds after it started.
    public func status(at elapsed: Double, repeats: Bool) -> IntervalStatus {
        let elapsed = max(0, elapsed)
        if !repeats && elapsed >= length {
            return IntervalStatus(round: 1, remaining: 0, displaySeconds: 0, fractionLeft: 0, phase: .final, finished: true)
        }
        let index = roundIndex(at: elapsed)
        let remaining = length - (elapsed - Double(index) * length)
        return IntervalStatus(
            round: index + 1,
            remaining: remaining,
            displaySeconds: Int(remaining.rounded(.up)),
            fractionLeft: remaining / length,
            phase: Phase(remaining: remaining),
            finished: false
        )
    }
}
