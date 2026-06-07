import SwiftUI

/// A circular power button rendered at a given diameter. The same logical
/// button is placed twice in `ContentView` (large+centered when OFF, small+
/// top-left when ON); `matchedGeometryEffect` morphs between the two layouts.
struct PowerButton: View {
    let isOn: Bool
    let diameter: CGFloat
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var pulse = false

    private var accent: Color { isOn ? Theme.green : Theme.pink }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Outer glow ring
                Circle()
                    .stroke(accent.opacity(0.35), lineWidth: diameter * 0.04)
                    .frame(width: diameter, height: diameter)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .opacity(pulse ? 0.5 : 1.0)

                // Body
                Circle()
                    .fill(Theme.card)
                    .frame(width: diameter * 0.86, height: diameter * 0.86)
                    .overlay(
                        Circle().stroke(accent, lineWidth: diameter * 0.03)
                    )
                    .shadow(color: accent.opacity(0.6), radius: diameter * 0.12)

                // Power glyph
                Image(systemName: "power")
                    .font(.system(size: diameter * 0.34, weight: .bold))
                    .foregroundStyle(accent)
            }
            .frame(width: diameter, height: diameter)
            .matchedGeometryEffect(id: "powerButton", in: namespace)
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

/// Full-screen standby overlay shown when the device is OFF: a centered power
/// button plus a hint label.
struct StandbyView: View {
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                PowerButton(isOn: false, diameter: 180, namespace: namespace, action: action)

                VStack(spacing: 8) {
                    Text("STANDBY")
                        .font(.pressStart(12))
                        .foregroundStyle(Theme.muted)
                    Text("Tap to wake the desk display")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.dim)
                }
                .matchedGeometryEffect(id: "standbyLabel", in: namespace)
            }
        }
    }
}

#Preview("Standby") {
    StandbyPreviewHost()
}

private struct StandbyPreviewHost: View {
    @Namespace var ns
    var body: some View { StandbyView(namespace: ns) {} }
}
