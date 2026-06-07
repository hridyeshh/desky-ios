import SwiftUI

struct ScreenPreviewSheet: View {
    let screenIndex: Int
    let widget: Widget?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ───────────────────────────────────────────────────
                HStack {
                    Text("SCREEN \(screenIndex)")
                        .font(.pressStart(10))
                        .foregroundStyle(Theme.fg)
                    Spacer()
                    Button { dismiss() } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.card)
                                .frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Theme.muted)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)

                // ── Display frame ────────────────────────────────────────────
                displayFrame
                    .padding(.horizontal, 24)

                Spacer(minLength: 20)

                // ── Widget info ──────────────────────────────────────────────
                if let w = widget {
                    widgetInfo(w)
                        .padding(.horizontal, 24)
                } else {
                    emptyInfo
                        .padding(.horizontal, 24)
                }

                Spacer(minLength: 40)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.bg)
    }

    // MARK: - Display frame

    private var displayFrame: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = w * 1.33

            ZStack {
                // Outer bezel
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(hex: "0D0D0D"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                (widget?.accent ?? Theme.line).opacity(0.35),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: (widget?.accent ?? Theme.cool).opacity(0.2),
                        radius: 24
                    )

                // Screen content
                if let w = widget {
                    WidgetPreviewView(widget: w)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(12)
                } else {
                    emptyScreen
                        .padding(12)
                }

                // Scan-line overlay
                scanLines
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(12)
                    .allowsHitTesting(false)
            }
            .frame(width: w, height: h)
        }
        .aspectRatio(1 / 1.33, contentMode: .fit)
    }

    // MARK: - Scan lines

    private var scanLines: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                ctx.fill(Path(rect), with: .color(.black.opacity(0.07)))
                y += 3
            }
        }
    }

    // MARK: - Empty screen

    private var emptyScreen: some View {
        VStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                .foregroundStyle(Theme.dim)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.dim)
                )
            Text("EMPTY")
                .font(.pressStart(7))
                .foregroundStyle(Theme.dim)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
    }

    // MARK: - Widget info pill

    private func widgetInfo(_ w: Widget) -> some View {
        HStack(spacing: 14) {
            PixelIconView(bitmap: w.bitmap, accent: w.accent, cellSize: 3.5)

            VStack(alignment: .leading, spacing: 5) {
                Text(w.displayName)
                    .font(.pressStart(9))
                    .foregroundStyle(w.accent)
                Text(w.tagline)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.muted)
            }

            Spacer()

            Circle()
                .fill(w.accent)
                .frame(width: 8, height: 8)
                .shadow(color: w.accent.opacity(0.6), radius: 6)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(widget?.accent.opacity(0.2) ?? Theme.line, lineWidth: 1)
        )
    }

    // MARK: - Empty info

    private var emptyInfo: some View {
        VStack(spacing: 8) {
            Text("NO WIDGET ASSIGNED")
                .font(.pressStart(7))
                .foregroundStyle(Theme.dim)
            Text("Drag a widget card from the library onto this screen slot")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview("With Widget – Clock") {
    ScreenPreviewSheet(screenIndex: 1, widget: .clock)
}

#Preview("With Widget – Music") {
    ScreenPreviewSheet(screenIndex: 2, widget: .music)
}

#Preview("With Widget – Weather") {
    ScreenPreviewSheet(screenIndex: 3, widget: .weather)
}

#Preview("Empty Slot") {
    ScreenPreviewSheet(screenIndex: 2, widget: nil)
}
