import CalloutCore
import SwiftUI

struct TimerView: View {
    @Bindable var model: TimerModel
    @ScaledMetric(relativeTo: .title) private var ringWidth = 18
    @ScaledMetric(relativeTo: .body) private var spacing = 28

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: model.state != .running)) { _ in
            let status = model.status()
            let finished = model.state == .finished
            let color = finished ? Palette.done : Palette.accent(status.phase)

            VStack(spacing: spacing) {
                header(status, finished: finished)
                ring(status, color: color, finished: finished)
                controls(color: color)
                Toggle("Repeat rounds", isOn: $model.repeats)
                    .font(.headline)
                    .tint(color)
                    .disabled(model.state == .running || model.state == .paused)
                    .frame(maxWidth: 320)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack {
                    Palette.background
                    color.opacity(finished ? 0.25 : glow(status))
                }
                .ignoresSafeArea()
            }
            .animation(.default, value: status.phase)
            .animation(.default, value: model.state)
            .animation(.default, value: status.displaySeconds)
        }
    }

    /// The background glows once the warning starts, and only while a round is live.
    private func glow(_ status: IntervalStatus) -> Double {
        model.state == .idle ? 0 : Palette.glow(status.phase)
    }

    private func header(_ status: IntervalStatus, finished: Bool) -> some View {
        Text(finished ? "Nice work" : model.repeats && model.state != .idle ? "Round \(status.round)" : "1 minute")
            .font(.title2.weight(.semibold))
            .foregroundStyle(.secondary)
    }

    private func ring(_ status: IntervalStatus, color: Color, finished: Bool) -> some View {
        let pulse = model.state == .running && status.phase == .final && status.displaySeconds.isMultiple(of: 2)
        return ZStack {
            Circle().stroke(Palette.track, lineWidth: ringWidth)
            Circle()
                .trim(from: 0, to: finished ? 1 : status.fractionLeft)
                .stroke(color, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
            GeometryReader { geo in
                Text(finished ? "Done" : timeText(status.displaySeconds))
                    .font(.system(size: geo.size.width * 0.28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(model.state == .idle ? .primary : color)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(ringWidth / 2)
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 480)
        .scaleEffect(pulse ? 1.04 : 1)
    }

    private func timeText(_ seconds: Int) -> String {
        "\(seconds / 60):" + String(format: "%02d", seconds % 60)
    }

    @ViewBuilder
    private func controls(color: Color) -> some View {
        HStack(spacing: spacing / 2) {
            switch model.state {
            case .idle, .finished:
                Button("Start", systemImage: "play.fill") { model.start() }
            case .running:
                Button("Pause", systemImage: "pause.fill") { model.pause() }
                Button("Reset", systemImage: "arrow.counterclockwise") { model.reset() }
                    .buttonStyle(.glass)
            case .paused:
                Button("Resume", systemImage: "play.fill") { model.resume() }
                Button("Reset", systemImage: "arrow.counterclockwise") { model.reset() }
                    .buttonStyle(.glass)
            }
        }
        .buttonStyle(.glassProminent)
        .tint(color)
        .controlSize(.extraLarge)
        .font(.title3.weight(.semibold))
    }
}
