import SwiftUI

struct ContentView: View {
    @State private var viewModel = DeskViewModel()
    @State private var connectivity = ConnectivityViewModel()
    @State private var draggingOver: Int? = nil
    @State private var previewSlot: PreviewSlot? = nil
    @State private var splashDone = false
    @Namespace private var powerNS

    struct PreviewSlot: Identifiable {
        let id: Int
        let widget: Widget?
    }

    private var powerSpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.8)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Theme.bg.ignoresSafeArea()

                if splashDone && connectivity.hasChecked && !connectivity.isConnected {
                    DisplayOfflineView()
                        .transition(.opacity)
                } else if viewModel.isPoweredOn {
                    VStack(spacing: 0) {
                        // Leave room for the morphed power button (top-left).
                        Spacer().frame(height: 44)

                        Spacer()

                        // ── Screens row ──────────────────────────────────────
                        screensSection
                            .padding(.horizontal, 16)

                        // ── Success toast ────────────────────────────────────
                        if let screen = viewModel.successScreen {
                            successToast(screen: screen)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        Spacer()

                        // ── GIF gallery ──────────────────────────────────────
                        GIFGalleryView(viewModel: viewModel)
                            .padding(.bottom, 8)

                        // ── Widget library ───────────────────────────────────
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WIDGETS")
                                .font(.pressStart(8))
                                .foregroundColor(Theme.muted)
                                .padding(.horizontal, 16)

                            WidgetLibraryView()
                        }
                        .padding(.bottom, 8)

                        // ── Footer ───────────────────────────────────────────
                        footer
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
                    }
                    .transition(.opacity)
                }

                // ── Power button layer (morphs between states) ───────────────
                if connectivity.isConnected {
                    powerButtonLayer
                }
            }
            .navigationTitle("")
            .toolbar { if viewModel.isPoweredOn { toolbarContent } }
            .task {
                connectivity.startPolling()
                async let loadTask: Void = viewModel.load()
                try? await Task.sleep(for: .seconds(2.5))
                await loadTask
                splashDone = true
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.successScreen)
            .animation(powerSpring, value: viewModel.isPoweredOn)
            .animation(.easeInOut(duration: 0.4), value: connectivity.isConnected)
            .sheet(item: $previewSlot) { slot in
                ScreenPreviewSheet(screenIndex: slot.id, widget: slot.widget)
            }
            .overlay {
                if !splashDone {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: splashDone)
        }
    }

    // MARK: - Power button layer

    private func togglePower() {
        Task { await viewModel.togglePower() }
    }

    @ViewBuilder
    private var powerButtonLayer: some View {
        if viewModel.isPoweredOn {
            // Small button morphed to the top-left corner.
            VStack {
                HStack {
                    PowerButton(isOn: true, diameter: 44, namespace: powerNS, action: togglePower)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }
        } else {
            // Full-screen standby with the large centered button.
            StandbyView(namespace: powerNS, action: togglePower)
                .transition(.opacity)
        }
    }

    // MARK: - Screens section

    @ViewBuilder
    private var screensSection: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingView

        case .loaded(let config):
            let widgets = [
                (1, Widget(rawValue: config.screen1)),
                (2, Widget(rawValue: config.screen2)),
                (3, Widget(rawValue: config.screen3))
            ]
            HStack(spacing: 10) {
                ForEach(widgets, id: \.0) { (index, widget) in
                    ScreenSlotView(
                        screenIndex: index,
                        widget: widget,
                        gifURL: config.gifURL(for: index),
                        isActive: draggingOver == index,
                        showBadge: viewModel.successScreen == index,
                        onTap: { previewSlot = PreviewSlot(id: index, widget: widget) }
                    )
                    .dropDestination(for: String.self) { items, _ in
                        guard let raw = items.first else { return false }
                        if raw.hasPrefix("http") {
                            // Dropped a GIF URL from the gallery.
                            Task { await viewModel.assignGif(url: raw, screen: index) }
                        } else if let dropped = Widget(rawValue: raw) {
                            Task { await viewModel.drop(widget: dropped, onto: index) }
                        } else {
                            return false
                        }
                        draggingOver = nil
                        return true
                    } isTargeted: { targeted in
                        draggingOver = targeted ? index : nil
                    }
                }
            }
            .frame(maxWidth: .infinity)

        case .error(let msg):
            errorView(msg)
        }
    }

    // MARK: - Success toast

    private func successToast(screen: Int) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Theme.green)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 3) {
                Text("SCREEN \(screen) UPDATED")
                    .font(.pressStart(7))
                    .foregroundColor(Theme.green)
                Text("Physical screen will refresh in ~5 seconds")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.green.opacity(0.094))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Theme.green.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(connectivity.isConnected ? Theme.green : Theme.pink)
                .frame(width: 6, height: 6)
            Text(connectivity.isConnected ? "CONNECTED" : "DISCONNECTED")
                .font(.pressStart(7))
                .foregroundColor(connectivity.isConnected ? Theme.green : Theme.pink)
                .animation(.easeInOut(duration: 0.3), value: connectivity.isConnected)
            Spacer()
            Text("SYNC \(viewModel.lastSyncText)")
                .font(.pressStart(7))
                .foregroundColor(Theme.dim)
        }
    }

    // MARK: - Loading / Error

    private var loadingView: some View {
        HStack(spacing: 10) {
            ForEach(1...3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.card)
                    .frame(width: 110, height: 147)
                    .overlay(
                        ProgressView()
                            .tint(Theme.muted)
                    )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 32))
                .foregroundColor(Theme.pink)
            Text("CONNECTION ERROR")
                .font(.pressStart(8))
                .foregroundColor(Theme.pink)
            Text(msg)
                .font(.system(size: 11))
                .foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)
            Button("RETRY") {
                Task { await viewModel.load() }
            }
            .font(.pressStart(8))
            .foregroundColor(Theme.amber)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("desky")
                .font(.pressStart(14))
                .foregroundColor(Theme.fg)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink(destination: SettingsView(viewModel: viewModel)) {
                GridIcon()
            }
        }
    }
}

// MARK: - Display offline screen

private struct DisplayOfflineView: View {
    @State private var pulsing = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .stroke(Theme.muted.opacity(pulsing ? 0.15 : 0.05), lineWidth: 40)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulsing ? 1.15 : 1.0)
                    Circle()
                        .stroke(Theme.muted.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 80, height: 80)
                    Image(systemName: "display")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundColor(Theme.muted)
                }
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: pulsing)

                VStack(spacing: 10) {
                    Text("DISPLAY OFFLINE")
                        .font(.pressStart(9))
                        .foregroundColor(Theme.muted)
                    Text("Waiting for desk display to connect…")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.dim)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
        }
        .onAppear { pulsing = true }
    }
}

// MARK: - Splash screen

private struct SplashView: View {
    @State private var glowing = false

    private let icons: [(Widget, Color)] = [
        (.clock, Theme.amber),
        (.music, Theme.pink),
        (.weather, Theme.cool),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 36) {
                // Three pixel icons with glow
                HStack(spacing: 32) {
                    ForEach(icons, id: \.0.rawValue) { widget, accent in
                        PixelIconView(bitmap: widget.bitmap, accent: accent, cellSize: 7)
                            .shadow(color: accent.opacity(glowing ? 0.7 : 0.2), radius: glowing ? 18 : 6)
                            .scaleEffect(glowing ? 1.05 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
                                .delay(Double(icons.firstIndex(where: { $0.0 == widget }) ?? 0) * 0.3),
                                value: glowing
                            )
                    }
                }

                // Wordmark
                Text("desky")
                    .font(.pressStart(20))
                    .foregroundStyle(Theme.fg)

                // Loading dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(Theme.dim)
                            .frame(width: 5, height: 5)
                    }
                }
                .opacity(glowing ? 1 : 0.4)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: glowing)
            }
        }
        .onAppear { glowing = true }
    }
}

// MARK: - Previews

#Preview("Splash") {
    SplashView()
}

#Preview("Home – Loading") {
    ContentView()
}

#Preview("Home – Loaded") {
    NavigationStack {
        ZStack(alignment: .bottom) {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    ScreenSlotView(screenIndex: 1, widget: .clock)
                    ScreenSlotView(screenIndex: 2, widget: .music)
                    ScreenSlotView(screenIndex: 3, widget: .weather)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                Spacer()
            }
        }
    }
}

// MARK: - Grid icon (2×2 pixel squares)

private struct GridIcon: View {
    var body: some View {
        let size: CGFloat = 5
        let gap: CGFloat = 3
        VStack(spacing: gap) {
            HStack(spacing: gap) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.muted)
                    .frame(width: size, height: size)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.muted)
                    .frame(width: size, height: size)
            }
            HStack(spacing: gap) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.muted)
                    .frame(width: size, height: size)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Theme.muted)
                    .frame(width: size, height: size)
            }
        }
        .frame(width: 20, height: 20)
    }
}
