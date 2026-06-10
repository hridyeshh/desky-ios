import SwiftUI

struct WidgetLibraryView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WIDGETS")
                .font(.custom("PressStart2P-Regular", size: 7))
                .foregroundStyle(Theme.muted)
                .tracking(2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Widget.libraryCases, id: \.rawValue) { widget in
                        WidgetCardView(widget: widget)
                            .draggable(widget.rawValue)
                    }
                }
                .padding(.bottom, 4)
            }

            Text("↑ DRAG A CARD ONTO A SCREEN SLOT")
                .font(.custom("PressStart2P-Regular", size: 6))
                .foregroundStyle(Theme.dim)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
