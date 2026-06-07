import SwiftUI

struct PixelIconView: View {
    let bitmap: [[Int]]
    let accent: Color
    var cellSize: CGFloat = 4

    var body: some View {
        Canvas { ctx, _ in
            for (r, row) in bitmap.enumerated() {
                for (c, val) in row.enumerated() where val != 0 {
                    let color: Color = val == 1 ? accent : Theme.fg
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
            width:  CGFloat(bitmap.first?.count ?? 0) * cellSize,
            height: CGFloat(bitmap.count) * cellSize
        )
    }
}

#Preview("Pixel Icons") {
    HStack(spacing: 20) {
        ForEach(Widget.allCases, id: \.rawValue) { widget in
            VStack(spacing: 8) {
                PixelIconView(bitmap: widget.bitmap, accent: widget.accent, cellSize: 5)
                Text(widget.displayName)
                    .font(.pressStart(5))
                    .foregroundStyle(Theme.muted)
            }
        }
    }
    .padding(24)
    .background(Theme.bg)
}
