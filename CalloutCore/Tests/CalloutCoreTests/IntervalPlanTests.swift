import Testing
@testable import CalloutCore

struct IntervalPlanTests {
    let plan = IntervalPlan(roundSeconds: 60)

    @Test func firstRoundCuesLandOnTheRightSeconds() {
        let cues = plan.cues(forRound: 0)
        #expect(cues.count == 17)
        #expect(cues.first == Cue(offset: 15, sound: .chime))
        #expect(cues.contains(Cue(offset: 30, sound: .thirty)))
        #expect(cues.contains(Cue(offset: 45, sound: .fifteen)))
        #expect(cues.contains(Cue(offset: 50, sound: .ten)))
        #expect(cues.filter { $0.sound == .tick }.map(\.offset) == [47, 48, 49, 51, 52, 53, 54])
        #expect(cues.suffix(6).map(\.sound) == [.five, .four, .three, .two, .one, .cheer])
        #expect(cues.last == Cue(offset: 60, sound: .cheer))
    }

    @Test func cuesAreInTimeOrder() {
        let offsets = plan.cues(forRound: 2).map(\.offset)
        #expect(offsets == offsets.sorted())
        #expect(offsets.first == 135)
        #expect(offsets.last == 180)
    }

    @Test func resumingSkipsCuesAlreadyPlayed() {
        let cues = plan.cues(from: 52.5, throughRound: 0)
        #expect(cues.map(\.offset) == [53, 54, 55, 56, 57, 58, 59, 60])
    }

    @Test func resumingAtACueKeepsIt() {
        #expect(plan.cues(from: 30, throughRound: 0).first == Cue(offset: 30, sound: .thirty))
    }

    @Test func resumingRightAfterARoundStillPlaysItsCheer() {
        // Elapsed 60 is round 1, but the cheer at 60 belongs to round 0.
        let cues = plan.cues(from: 60, throughRound: 1)
        #expect(cues.first == Cue(offset: 60, sound: .cheer))
        #expect(cues.last == Cue(offset: 120, sound: .cheer))
    }

    @Test func statusCountsDown() {
        let start = plan.status(at: 0, repeats: false)
        #expect(start.displaySeconds == 60)
        #expect(start.phase == .calm)
        #expect(start.fractionLeft == 1)

        #expect(plan.status(at: 30, repeats: false).phase == .warning)
        #expect(plan.status(at: 29.9, repeats: false).phase == .calm)
        #expect(plan.status(at: 45, repeats: false).displaySeconds == 15)
        #expect(plan.status(at: 45, repeats: false).phase == .closing)
        #expect(plan.status(at: 55, repeats: false).phase == .final)
        #expect(plan.status(at: 59.5, repeats: false).displaySeconds == 1)
    }

    @Test func singleRoundFinishesAtZero() {
        let end = plan.status(at: 60, repeats: false)
        #expect(end.finished)
        #expect(end.displaySeconds == 0)
    }

    @Test func repeatingRollsIntoTheNextRound() {
        let next = plan.status(at: 60, repeats: true)
        #expect(!next.finished)
        #expect(next.round == 2)
        #expect(next.displaySeconds == 60)
        #expect(plan.status(at: 185, repeats: true).round == 4)
    }

    @Test func roundsShorterThanTheCuesAreLengthened() {
        #expect(IntervalPlan(roundSeconds: 10).roundSeconds == IntervalPlan.minimumSeconds)
    }
}
