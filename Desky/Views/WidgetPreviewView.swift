import SwiftUI

struct PixelIcon: View {
    let bitmap: [[Int]]
    let accent: Color
    var cellSize: CGFloat = 4

    var body: some View {
        Canvas { ctx, _ in
            for (r, row) in bitmap.enumerated() {
                for (c, value) in row.enumerated() where value != 0 {
                    let color: Color = value == 1 ? accent : Theme.fg
                    let rect = CGRect(
                        x: CGFloat(c) * cellSize,
                        y: CGFloat(r) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(
            width: CGFloat(bitmap.first?.count ?? 0) * cellSize,
            height: CGFloat(bitmap.count) * cellSize
        )
    }
}

struct WidgetPreviewView: View {
    let widget: Widget

    var body: some View {
        Group {
            switch widget {
            case .clock: ClockPreview()
            case .weather: WeatherPreview()
            case .music: MusicPreview()
            case .timer: TimerPreview()
            case .gif: GifPreview()
            case .quote: QuotePreview()
            case .pet: PetPreview()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ClockPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("IST")
                .font(.pressStart(6))
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 6)
                .padding(.top, 8)
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                Text("14:32")
                    .font(.vt323(32))
                    .foregroundStyle(Theme.amber)
                    .monospacedDigit()
                Text("SATURDAY")
                    .font(.pressStart(5))
                    .foregroundStyle(Theme.fg)
                Text("06 JUN")
                    .font(.pressStart(5))
                    .foregroundStyle(Theme.amber)
            }
            Spacer(minLength: 0)
            progressStrip(color: Theme.amber, fraction: 0.47)
        }
        .background(Theme.bg)
    }
}

private struct MusicPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("NOW PLAYING")
                .font(.pressStart(5))
                .foregroundStyle(Theme.pink)
                .padding(.horizontal, 6)
                .padding(.top, 8)
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                PixelIcon(bitmap: Widget.music.bitmap, accent: Theme.pink, cellSize: 3)
                Text("Midnight City")
                    .font(.pressStart(5))
                    .foregroundStyle(Theme.fg)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                Text("M83")
                    .font(.pressStart(4))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.horizontal, 4)
            Spacer(minLength: 0)
            progressStrip(color: Theme.pink, fraction: 0.34)
        }
        .background(Theme.bg)
    }
}

private struct WeatherPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BANGALORE")
                .font(.pressStart(5))
                .foregroundStyle(Theme.muted)
                .padding(.horizontal, 6)
                .padding(.top, 8)
            Spacer(minLength: 0)
            HStack {
                Text("28°")
                    .font(.vt323(34))
                    .foregroundStyle(Theme.cool)
                Spacer()
                PixelIcon(bitmap: Widget.weather.bitmap, accent: Theme.cool, cellSize: 3.5)
            }
            .padding(.horizontal, 6)
            Text("PARTLY CLOUDY")
                .font(.pressStart(4))
                .foregroundStyle(Theme.fg)
                .padding(.horizontal, 6)
                .padding(.bottom, 8)
            Spacer(minLength: 0)
        }
        .background(Theme.bg)
    }
}

private struct TimerPreview: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("TIMER")
                .font(.pressStart(5))
                .foregroundStyle(Theme.muted)
            Spacer(minLength: 0)
            Text("25:00")
                .font(.pressStart(14))
                .foregroundStyle(Theme.green)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 8)
        .background(Theme.bg)
    }
}

private struct GifPreview: View {
    private let palette = [
        Color(hex: "0b1226"),
        Color(hex: "2a2350"),
        Color(hex: "9a4257"),
        Color(hex: "e69a4a"),
        Theme.amber,
        Color(hex: "15161f"),
        Color(hex: "0c0c0c"),
    ]

    private let grid: [[Int]] = [
        [0, 0, 0, 0, 0],
        [0, 1, 0, 2, 0],
        [0, 2, 3, 2, 0],
        [3, 3, 4, 3, 3],
        [5, 4, 4, 4, 5],
        [6, 5, 4, 5, 6],
        [6, 6, 6, 6, 6],
    ]

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Canvas { ctx, size in
                let cols = grid[0].count
                let rows = grid.count
                let cw = size.width / CGFloat(cols)
                let ch = size.height / CGFloat(rows)
                for (r, row) in grid.enumerated() {
                    for (c, idx) in row.enumerated() {
                        let rect = CGRect(
                            x: CGFloat(c) * cw,
                            y: CGFloat(r) * ch,
                            width: cw + 1,
                            height: ch + 1
                        )
                        ctx.fill(Path(rect), with: .color(palette[idx]))
                    }
                }
            }
            Text("GIF")
                .font(.pressStart(5))
                .foregroundStyle(Theme.fg)
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Theme.bg.opacity(0.8))
                .padding(6)
        }
        .background(Theme.bg)
    }
}

private struct QuotePreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PixelIcon(bitmap: Widget.quote.bitmap, accent: Theme.amber, cellSize: 3)
                .padding(.horizontal, 6)
                .padding(.top, 8)
            Spacer(minLength: 0)
            Text("Stay hungry, stay foolish.")
                .font(.pressStart(5))
                .foregroundStyle(Theme.fg)
                .padding(.horizontal, 6)
            Spacer(minLength: 0)
            Text("— STEVE JOBS")
                .font(.pressStart(4))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 6)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Theme.bg)
    }
}

private struct PetPreview: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("PIXEL")
                .font(.pressStart(5))
                .foregroundStyle(Theme.muted)
                .padding(.top, 8)
            Spacer(minLength: 0)
            PixelIcon(bitmap: Widget.pet.bitmap, accent: Theme.green, cellSize: 4)
            Spacer(minLength: 0)
            // Happiness bar.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.line)
                    Capsule().fill(Theme.green).frame(width: geo.size.width * 0.8)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }
}

// MARK: - Previews

#Preview("Clock") { WidgetPreviewView(widget: .clock).frame(width: 110, height: 140).background(Theme.bg) }
#Preview("Music") { WidgetPreviewView(widget: .music).frame(width: 110, height: 140).background(Theme.bg) }
#Preview("Weather") { WidgetPreviewView(widget: .weather).frame(width: 110, height: 140).background(Theme.bg) }
#Preview("Timer") { WidgetPreviewView(widget: .timer).frame(width: 110, height: 140).background(Theme.bg) }
#Preview("GIF") { WidgetPreviewView(widget: .gif).frame(width: 110, height: 140).background(Theme.bg) }

#Preview("All Widgets") {
    HStack(spacing: 10) {
        ForEach(Widget.allCases, id: \.rawValue) { widget in
            WidgetPreviewView(widget: widget)
                .frame(width: 90, height: 120)
                .background(Theme.card)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    .padding(16)
    .background(Theme.bg)
}

@ViewBuilder
private func progressStrip(color: Color, fraction: CGFloat) -> some View {
    GeometryReader { geo in
        ZStack(alignment: .leading) {
            Rectangle().fill(Theme.line)
            Rectangle()
                .fill(color)
                .frame(width: geo.size.width * fraction)
        }
    }
    .frame(height: 3)
}
