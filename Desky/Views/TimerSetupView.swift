import SwiftUI

/// Bottom panel for the countdown timer: pick a duration, then drag the timer
/// chip onto a screen slot. The drag payload is "timer:<minutes>" so the drop
/// handler in ContentView can start the countdown on that screen.
struct TimerSetupView: View {
    @State private var minutes: Int = 25

    private let presets = [5, 10, 15, 25, 45]

    private var label: String {
        String(format: "%02d:00", minutes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TIMER")
                    .font(.pressStart(8))
                    .foregroundColor(Theme.muted)
                Spacer()
                Text("\(minutes) MIN")
                    .font(.pressStart(7))
                    .foregroundColor(Theme.green)
            }
            .padding(.horizontal, 16)

            // Preset duration chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { m in
                        Button {
                            minutes = m
                        } label: {
                            Text("\(m)m")
                                .font(.pressStart(7))
                                .foregroundColor(minutes == m ? Theme.bg : Theme.green)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(minutes == m ? Theme.green : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Theme.green.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    // Fine adjust
                    Stepper("", value: $minutes, in: 1...180)
                        .labelsHidden()
                        .tint(Theme.green)
                }
                .padding(.horizontal, 16)
            }

            // Draggable timer chip
            HStack {
                Spacer()
                timerChip
                    .draggable("timer:\(minutes)")
                Spacer()
            }
            .padding(.top, 2)

            Text("↑ DRAG THE TIMER ONTO A SCREEN SLOT")
                .font(.pressStart(6))
                .foregroundColor(Theme.dim)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var timerChip: some View {
        HStack(spacing: 8) {
            Image(systemName: "hourglass")
                .font(.system(size: 13, weight: .bold))
            Text(label)
                .font(.pressStart(12))
        }
        .foregroundColor(Theme.green)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Theme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.green.opacity(0.6), lineWidth: 1.5)
        )
        .shadow(color: Theme.green.opacity(0.25), radius: 8)
    }
}

#Preview {
    VStack {
        Spacer()
        TimerSetupView()
            .padding(.bottom, 20)
    }
    .background(Theme.bg)
}
