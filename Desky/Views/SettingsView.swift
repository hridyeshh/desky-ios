import SwiftUI

struct SettingsView: View {
    var viewModel: DeskViewModel
    @State private var isRefreshing = false
    @State private var showWiFiSetup = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    backendSection
                    displayConfigSection
                    provisioningSection
                    forceRefreshButton
                    aboutSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
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
