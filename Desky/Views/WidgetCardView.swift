import SwiftUI

struct WidgetCardView: View {
    let widget: Widget
    var isLifted: Bool = false

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
            }
            .padding(.horizontal, 12)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .frame(width: 136, height: 84, alignment: .topLeading)

            // drag handle lines
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Theme.dim)
                        .frame(width: 18, height: 2)
                }
            }
            .padding(10)
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
}

#Preview("Widget Cards") {
    ScrollView(.horizontal) {
        HStack(spacing: 12) {
            ForEach(Widget.allCases, id: \.rawValue) { widget in
                WidgetCardView(widget: widget)
            }
            WidgetCardView(widget: .clock, isLifted: true)
        }
        .padding(20)
    }
    .background(Theme.bg)
}
