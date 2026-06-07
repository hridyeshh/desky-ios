import SwiftUI

struct ScreenSlotView: View {
    let screenIndex: Int
    let widget: Widget?
    var gifURL: String = ""
    var isActive: Bool = false
    var showBadge: Bool = false
    var onTap: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // ── Main slot card ───────────────────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                isActive
                                    ? (widget.map { $0.accent } ?? Theme.cool).opacity(0.9)
                                    : (widget.map { $0.accent } ?? Theme.line).opacity(isActive ? 0.9 : 0.5),
                                lineWidth: isActive ? 2 : 1
                            )
                    )
                    .shadow(
                        color: (widget.map { $0.accent } ?? Theme.cool)
                            .opacity(isActive ? 0.45 : 0.18),
                        radius: isActive ? 14 : 8
                    )

                VStack(spacing: 8) {
                    if widget == .gif, !gifURL.isEmpty {
                        AsyncImage(url: URL(string: gifURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                Image(systemName: "photo")
                                    .foregroundColor(Theme.dim)
                            default:
                                ProgressView().tint(Theme.muted)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else if let w = widget {
                        WidgetPreviewView(widget: w)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        emptySlot
                    }

                    Text("SCREEN \(screenIndex)")
                        .font(.pressStart(6))
                        .foregroundColor(Theme.dim)
                }
                .padding(10)
            }
            .frame(width: 110, height: 147)
            .scaleEffect(isActive ? 1.04 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isActive)
            .onTapGesture { onTap?() }

            // ── Success badge ────────────────────────────────────────
            if showBadge {
                ZStack {
                    Circle()
                        .fill(Theme.green)
                        .frame(width: 22, height: 22)
                        .shadow(color: Theme.green.opacity(0.5), radius: 6)

                    // Pixel checkmark (3×3 dot pattern)
                    PixelCheckmark()
                }
                .offset(x: 8, y: -8)
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showBadge)
            }
        }
    }

    // MARK: - Empty slot

    private var emptySlot: some View {
        VStack(spacing: 6) {
            // Dashed drop zone
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
                .foregroundColor(Theme.line)
                .frame(width: 72, height: 72)
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.system(size: 14))
                            .foregroundColor(Theme.dim)
                        Text("DROP")
                            .font(.pressStart(5))
                            .foregroundColor(Theme.dim)
                    }
                )
            Text("EMPTY")
                .font(.pressStart(6))
                .foregroundColor(Theme.dim)
        }
    }
}

// MARK: - Previews

#Preview("Loaded") {
    HStack(spacing: 10) {
        ScreenSlotView(screenIndex: 1, widget: .clock)
        ScreenSlotView(screenIndex: 2, widget: .music, isActive: true)
        ScreenSlotView(screenIndex: 3, widget: nil)
    }
    .padding(20)
    .background(Theme.bg)
}

#Preview("Success Badge") {
    ScreenSlotView(screenIndex: 1, widget: .weather, showBadge: true)
        .padding(40)
        .background(Theme.bg)
}

// MARK: - Pixel checkmark

private struct PixelCheckmark: View {
    // A minimal 5-column pixel checkmark rendered as small squares
    private let pixels: [(Int, Int)] = [
        (3, 0),
        (2, 1),
        (3, 1),
        (0, 2),
        (1, 2),
        (2, 2)
    ]

    var body: some View {
        let size: CGFloat = 2.5
        Canvas { ctx, _ in
            for (col, row) in pixels {
                let rect = CGRect(
                    x: CGFloat(col) * size + 2,
                    y: CGFloat(row) * size + 5,
                    width: size,
                    height: size
                )
                ctx.fill(Path(rect), with: .color(.white))
            }
        }
        .frame(width: 22, height: 22)
    }
}
