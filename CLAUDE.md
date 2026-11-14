# Callout

An iOS workout interval timer. Each round is one minute. A digital chime plays at 0:45, then a deep male voice calls the rest: "Thirty seconds" at 0:30, "Fifteen" at 0:15, a tick each second from 0:14 to 0:06 with "Ten" at 0:10, then "Five, four, three, two, one" and applause and cheering at zero. With "Repeat" on (off by default), the next round starts the moment the cheer plays and the header counts rounds.

## Layout

- `CalloutCore/` is a Swift package holding all timing. `IntervalPlan` lists each round's cues (`cues(forRound:)`, `cues(from:throughRound:)`) and turns elapsed seconds into an `IntervalStatus` (round, time left, whole seconds to show, fraction left, `Phase`, finished). `Phase` is calm above 0:30, warning to 0:15, closing to 0:05, and final after that. Rounds are at least 46 seconds so every cue fits. It is pure Swift and builds for iOS and macOS.
- `Callout/` is the SwiftUI app.
  - `CueAudio` plays the cues on an `AVAudioEngine`, scheduling each buffer at an exact host time. Short cues alternate between two player nodes so a long voice line never delays the next; the cheer has its own node so it can ring into the next round. The session is `.playback` with `.mixWithOthers`, so it ignores the silent switch and plays over the user's music. The `audio` background mode (in `Config/Info.plist`) and the running engine keep the timer going while the phone is locked. A call, Siri or an engine configuration change (such as headphones unplugging) pauses the session.
  - `TimerModel` runs the session against the host clock with pause, resume and reset. It queues one round ahead when repeating and wakes only at round boundaries to queue the next, or to finish a single round. The screen stays awake while running.
  - `TimerView` draws the ring, time, controls and the repeat toggle inside a `TimelineView`. The ring and background heat from teal to amber, orange and red by phase, and the ring pulses each second during the final five. The toggle is locked while a session is running or paused.
  - `Palette` holds the colors. The app is always dark and portrait, iPhone only.
  - `Sounds/` holds the bundled WAVs. See `SOUNDS.md`.
- `tools/voice.py` makes voice lines with ElevenLabs text-to-speech, `tools/prep_audio.py` trims, normalizes and copies `sounds-src/` into `Callout/Sounds/` and synthesizes the tick, and `tools/make_icon.swift` renders the app icon.

## Build and test

`project.yml` is the source of truth; regenerate the Xcode project after changing it or adding targets.

```bash
xcodegen generate
```

```bash
cd CalloutCore && swift test
```

Build a signed device build (automatic signing, team `XWQQQ8GD2Z`, bundle ID `com.redmesastudios.Callout`), then install it with `xcrun devicectl device install app --device <id> build/Build/Products/Debug-iphoneos/Callout.app`:

```bash
xcodebuild -project Callout.xcodeproj -scheme Callout -destination 'generic/platform=iOS' -configuration Debug -derivedDataPath build -allowProvisioningUpdates build
```

## Rules for changes

- Timing rules belong in `CalloutCore` and come with tests. The app never computes cue times itself.
- Every visible state change animates with a plain `.animation(.default, value:)`. Nothing snaps.
- UI sizes use `@ScaledMetric`, semantic fonts or sizes derived from the layout, never hard-coded values. Dynamic Type is capped at `.accessibility3`.
- The project uses Swift 6 and iOS 26, with `MainActor` as the default actor isolation. Callbacks the system runs off the main thread must be built in `nonisolated` code.
- Swift Testing's `#expect` and `#require` can't wrap a `mutating` call; assign the result to a `let` first.
- Commit messages go in a temp file and use `git commit -F`; use `git -C <path>` rather than `cd` and git together.
