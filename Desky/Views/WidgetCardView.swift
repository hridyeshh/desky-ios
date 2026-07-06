import SwiftUI

struct WidgetCardView: View {
    let widget: Widget
    var isLifted: Bool = false
    /// When non-nil and widget == .quote, a SHUFFLE button is rendered.
    var onShuffle: (() -> Void)? = nil
    /// Drives the in-flight spinner on the SHUFFLE button.
    var isShuffling: Bool = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 9) {
                    PixelIconView(bitmap: widget.bitmap, accent: widget.accent, cellSize: 3)
                    Text(widget.displayName)
                        .font(.custom("PressStart2P-Regular", size: 7))
                        .foregroundStyle(Theme.fg)
                }
                Text(widget.tagline)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(2)

                // SHUFFLE button — only visible on the quote card
                if widget == .quote, let onShuffle {
                    shuffleButton(onShuffle: onShuffle)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .frame(width: 136, alignment: .topLeading)

            // drag handle lines (hidden when the shuffle button is showing
            // so the two affordances don't visually collide)
            if !(widget == .quote && onShuffle != nil) {
                VStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { _ in
                        Rectangle()
                            .fill(Theme.dim)
                            .frame(width: 18, height: 2)
                    }
                }
                .padding(10)
            }
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isLifted ? widget.accent : Theme.line,
                    lineWidth: 1
                )
        }
        .shadow(
            color: isLifted ? widget.accent.opacity(0.25) : .clear,
            radius: isLifted ? 16 : 0,
            y: isLifted ? 10 : 0
        )
        .scaleEffect(isLifted ? 1.07 : 1)
        .rotationEffect(isLifted ? .degrees(-2) : .zero)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLifted)
    }

    // MARK: - Shuffle button

    @ViewBuilder
    private func shuffleButton(onShuffle: @escaping () -> Void) -> some View {
        Button {
            onShuffle()
        } label: {
            HStack(spacing: 5) {
                if isShuffling {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.55)
                        .tint(Theme.amber)
                        .frame(width: 10, height: 10)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(Theme.amber)
                }
                Text(isShuffling ? "SHUFFLING" : "SHUFFLE")
                    .font(.custom("PressStart2P-Regular", size: 6))
                    .foregroundStyle(isShuffling ? Theme.muted : Theme.amber)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Theme.amber.opacity(0.10), in: RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Theme.amber.opacity(isShuffling ? 0.2 : 0.45), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isShuffling)
        .animation(.easeInOut(duration: 0.2), value: isShuffling)
    }
}

#Preview("Widget Cards") {
    ScrollView(.horizontal) {
        HStack(spacing: 12) {
            ForEach(Widget.allCases, id: \.rawValue) { widget in
                WidgetCardView(widget: widget)
            }
            WidgetCardView(widget: .clock, isLifted: true)
            WidgetCardView(widget: .quote, onShuffle: {}, isShuffling: false)
            WidgetCardView(widget: .quote, onShuffle: {}, isShuffling: true)
        }
        .padding(20)
    }
    .background(Theme.bg)
}
