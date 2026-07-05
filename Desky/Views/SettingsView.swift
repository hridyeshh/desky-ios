import SwiftUI
import UIKit

struct SettingsView: View {
    var viewModel: DeskViewModel
    @State private var isRefreshing = false
    @State private var showWiFiSetup = false
    @State private var pet: DeskAPI.Pet?
    @State private var isFeeding = false
    @State private var feedScale: CGFloat = 1

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    backendSection
                    displayConfigSection
                    petSection
                    provisioningSection
                    forceRefreshButton
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .task { pet = try? await DeskAPI.fetchPet() }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("SETTINGS")
                    .font(.pressStart(11))
                    .foregroundColor(Theme.fg)
            }
        }
        .sheet(isPresented: $showWiFiSetup) {
            NavigationStack { WiFiSetupView() }
        }
    }

    // MARK: - Provisioning section

    private var provisioningSection: some View {
        sectionCard(title: "DEVICE SETUP") {
            Button {
                showWiFiSetup = true
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Theme.pink.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "wifi.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Theme.pink)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROVISION WI-FI")
                            .font(.pressStart(7))
                            .foregroundColor(Theme.fg)
                        Text("Set up office network via hotspot")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.dim)
                }
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Pet section

    private var petSection: some View {
        VStack(spacing: 12) {
            sectionCard(title: "YOUR PET") {
                VStack(spacing: 14) {
                    Text(pet?.name.uppercased() ?? "PIXEL")
                        .font(.pressStart(10))
                        .foregroundColor(Theme.fg)
                    Text("· \(pet?.state.uppercased() ?? "HAPPY")")
                        .font(.pressStart(6))
                        .foregroundColor(petStateColor)

                    PetSprite()
                        .frame(width: 132, height: 120)

                    VStack(spacing: 8) {
                        HStack {
                            Text("HAPPINESS")
                                .font(.pressStart(6))
                                .foregroundColor(Theme.muted)
                            Spacer()
                            Text("\(pet?.happiness ?? 80)")
                                .font(.pressStart(6))
                                .foregroundColor(Theme.fg)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.line)
                                Capsule().fill(petBarColor)
                                    .frame(width: geo.size.width * CGFloat(pet?.happiness ?? 80) / 100)
                            }
                        }
                        .frame(height: 6)
                        Text("LAST FED \(petLastFedText)")
                            .font(.pressStart(5))
                            .foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            feedButton
        }
    }

    private var feedButton: some View {
        Button(action: feed) {
            VStack(spacing: 5) {
                HStack(spacing: 10) {
                    PixelIcon(bitmap: Widget.pet.bitmap, accent: Theme.bg, cellSize: 3)
                    Text(isFeeding ? "FED!" : "FEED \(pet?.name.uppercased() ?? "PIXEL")")
                        .font(.pressStart(9))
                        .foregroundColor(Theme.bg)
                }
                Text("+20 HAPPINESS · RESETS THE HUNGER TIMER")
                    .font(.pressStart(5))
                    .foregroundColor(Theme.bg.opacity(0.65))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.amber)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .scaleEffect(feedScale)
        }
        .disabled(isFeeding)
    }

    private var petStateColor: Color {
        switch pet?.state {
        case "content": Theme.amber
        case "sad":     Theme.muted
        case "sleepy":  Theme.cool
        default:        Theme.green
        }
    }

    private var petBarColor: Color {
        let h = pet?.happiness ?? 80
        return h >= 50 ? Theme.green : (h >= 20 ? Theme.amber : Theme.pink)
    }

    private var petLastFedText: String {
        guard let h = pet?.hoursSinceFed else { return "—" }
        return h <= 0 ? "JUST NOW" : "\(h)H AGO"
    }

    private func feed() {
        guard !isFeeding else { return }
        isFeeding = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.22, dampingFraction: 0.35)) { feedScale = 1.25 }
        Task {
            let updated = try? await DeskAPI.feedPet()
            await MainActor.run {
                if let updated { pet = updated }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { feedScale = 1 }
                isFeeding = false
            }
        }
    }

    // MARK: - Backend section

    private var backendSection: some View {
        sectionCard(title: "BACKEND") {
            settingsRow(label: "API STATUS") {
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isConnected ? Theme.green : Theme.pink)
                        .frame(width: 7, height: 7)
                    Text(viewModel.isConnected ? "OK" : "ERROR")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(viewModel.isConnected ? Theme.green : Theme.pink)
                }
            }

            Divider().background(Theme.line)

            settingsRow(label: "LAST SYNCED") {
                Text(viewModel.lastSyncText)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
            }

            Divider().background(Theme.line)

            settingsRow(label: "SCREENS") {
                Text("3")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
            }
        }
    }

    // MARK: - Display config section

    private var displayConfigSection: some View {
        sectionCard(title: "DISPLAY CONFIG") {
            if case .loaded(let config) = viewModel.loadState {
                let rows: [(Int, String)] = [
                    (1, config.screen1),
                    (2, config.screen2),
                    (3, config.screen3)
                ]
                ForEach(Array(rows.enumerated()), id: \.offset) { idx, pair in
                    let (screenNum, rawValue) = pair
                    if idx > 0 {
                        Divider().background(Theme.line)
                    }
                    settingsRow(label: "SCREEN \(screenNum)") {
                        HStack(spacing: 6) {
                            if let widget = Widget(rawValue: rawValue) {
                                Circle()
                                    .fill(widget.accent)
                                    .frame(width: 6, height: 6)
                                Text(widget.displayName.uppercased())
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.fg)
                            } else {
                                Text("EMPTY")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.dim)
                            }
                        }
                    }
                }
            } else {
                Text("Loading…")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.muted)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Force refresh button

    private var forceRefreshButton: some View {
        Button {
            isRefreshing = true
            Task {
                await viewModel.refresh()
                isRefreshing = false
            }
        } label: {
            HStack(spacing: 10) {
                // Clock pixel icon (simplified 5×5 grid)
                ClockPixelIcon()
                    .frame(width: 16, height: 16)

                if isRefreshing {
                    ProgressView()
                        .tint(Theme.amber)
                        .scaleEffect(0.8)
                    Text("REFRESHING…")
                        .font(.pressStart(8))
                        .foregroundColor(Theme.amber)
                } else {
                    Text("FORCE REFRESH")
                        .font(.pressStart(8))
                        .foregroundColor(Theme.amber)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.amber.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Theme.amber.opacity(0.30), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isRefreshing)
    }

    // MARK: - About section

    private var aboutSection: some View {
        sectionCard(title: "ABOUT") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("desky v1.0")
                            .font(.pressStart(9))
                            .foregroundColor(Theme.fg)
                        Text("A pixel-art dashboard controller for your physical desk display. Drag widgets from your phone to your screen.")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .padding(.bottom, 4)

                Divider().background(Theme.line)

                linkRow(label: "GITHUB", value: "github.com/hridyeshh/desky", icon: "arrow.up.right.square")
                Divider().background(Theme.line)
                linkRow(label: "BACKEND", value: "desky.up.railway.app", icon: "server.rack")
            }
        }
    }

    // MARK: - Reusable components

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.pressStart(7))
                .foregroundColor(Theme.muted)
                .padding(.bottom, 8)
                .padding(.horizontal, 2)

            VStack(spacing: 0) {
                content()
            }
            .padding(14)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.line, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func settingsRow<Value: View>(label: String, @ViewBuilder value: () -> Value) -> some View {
        HStack {
            Text(label)
                .font(.pressStart(7))
                .foregroundColor(Theme.fg)
            Spacer()
            value()
        }
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private func linkRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Text(label)
                .font(.pressStart(7))
                .foregroundColor(Theme.fg)
            Spacer()
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.cool)
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.cool)
            }
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Previews

#Preview("Settings – Connected") {
    let vm = DeskViewModel()
    vm.loadState = .loaded(Config(screen1: "clock", screen2: "music", screen3: "weather"))
    vm.isConnected = true
    vm.lastSyncText = "12:30"
    return NavigationStack { SettingsView(viewModel: vm) }
}

#Preview("Settings – Offline") {
    let vm = DeskViewModel()
    vm.isConnected = false
    return NavigationStack { SettingsView(viewModel: vm) }
}

// MARK: - Pet sprite

/// Front-facing pixel hamster (matches the Pi widget + design mockup).
/// Palette: 1 body, 2 belly, 3 cheek, 4 dark.
struct PetSprite: View {
    static let grid: [[Int]] = [
        [0,0,0,1,1,0,0,1,1,0,0,0],
        [0,0,1,1,1,1,1,1,1,1,0,0],
        [0,1,1,1,1,1,1,1,1,1,1,0],
        [1,1,1,1,1,1,1,1,1,1,1,1],
        [1,1,4,1,1,1,1,1,1,4,1,1],
        [1,3,3,1,1,2,2,1,1,3,3,1],
        [1,3,3,1,2,2,2,2,1,3,3,1],
        [1,1,1,1,2,4,4,2,1,1,1,1],
        [0,1,1,1,2,2,2,2,1,1,1,0],
        [0,0,1,1,1,2,2,1,1,1,0,0],
        [0,0,0,1,1,1,1,1,1,0,0,0],
    ]
    static let palette: [Int: Color] = [
        1: Color(hex: "E6A15A"),
        2: Color(hex: "F5D3A8"),
        3: Color(hex: "F58DA0"),
        4: Color(hex: "0A0A0A"),
    ]

    var body: some View {
        Canvas { ctx, size in
            let cols = Self.grid[0].count, rows = Self.grid.count
            let cell = min(size.width / CGFloat(cols), size.height / CGFloat(rows))
            let ox = (size.width - cell * CGFloat(cols)) / 2
            let oy = (size.height - cell * CGFloat(rows)) / 2
            for (r, row) in Self.grid.enumerated() {
                for (c, v) in row.enumerated() where v != 0 {
                    guard let color = Self.palette[v] else { continue }
                    let rect = CGRect(x: ox + CGFloat(c) * cell, y: oy + CGFloat(r) * cell,
                                      width: cell + 0.5, height: cell + 0.5)
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}

// MARK: - Clock pixel icon

private struct ClockPixelIcon: View {
    // Simple 5×5 clock face using Canvas
    var body: some View {
        Canvas { ctx, size in
            let s = size.width / 5
            // Outer ring pixels
            let ring: [(Int, Int)] = [
                (1,0),(2,0),(3,0),
                (0,1),(4,1),
                (0,2),(4,2),
                (0,3),(4,3),
                (1,4),(2,4),(3,4)
            ]
            // Clock hands (12 o'clock + 3 o'clock position)
            let hands: [(Int, Int)] = [(2,1),(2,2),(3,2)]

            for (col, row) in ring {
                let rect = CGRect(x: CGFloat(col)*s, y: CGFloat(row)*s, width: s-0.5, height: s-0.5)
                ctx.fill(Path(rect), with: .color(Theme.amber))
            }
            for (col, row) in hands {
                let rect = CGRect(x: CGFloat(col)*s, y: CGFloat(row)*s, width: s-0.5, height: s-0.5)
                ctx.fill(Path(rect), with: .color(Theme.amber))
            }
        }
    }
}
