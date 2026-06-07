import SwiftUI

// MARK: - Model

struct WiFiNetwork: Identifiable, Decodable {
    var id: String { ssid }
    let ssid: String
    /// Signal strength as a 0–100 percentage (comitup "strength" field).
    let strength: String
    /// Whether the network requires a password.
    let keyed: Bool

    enum CodingKeys: String, CodingKey {
        case ssid, strength, keyed
    }

    /// Normalised 0–1 fraction for the signal bar.
    var signalFraction: Double {
        (Double(strength) ?? 0) / 100.0
    }

    var signalColor: Color {
        let f = signalFraction
        if f >= 0.65 { return Theme.green }
        if f >= 0.35 { return Theme.amber }
        return Theme.pink
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class WiFiSetupViewModel {
    var networks: [WiFiNetwork] = []
    var isScanning = false
    var statusMessage: String? = nil
    var didProvision = false

    // comitup default gateway on the Pi hotspot
    private let base = "http://10.42.0.1/api/v1"

    func scan() async {
        isScanning = true
        statusMessage = nil
        defer { isScanning = false }

        guard let url = URL(string: "\(base)/access-points") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([WiFiNetwork].self, from: data)
            networks = decoded.sorted { $0.signalFraction > $1.signalFraction }
        } catch {
            statusMessage = "COULDN'T REACH DESKY HOTSPOT"
        }
    }

    func connect(ssid: String, password: String) async {
        guard let url = URL(string: "\(base)/connect") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["ssid": ssid, "password": password])
        req.timeoutInterval = 8

        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if (resp as? HTTPURLResponse)?.statusCode == 200 {
                statusMessage = "CONNECTING… DESKY WILL JOIN YOUR NETWORK"
                didProvision = true
            } else {
                statusMessage = "PI REJECTED THE CREDENTIALS"
            }
        } catch {
            // Pi drops the hotspot immediately on success — treat a connection
            // reset as a good sign rather than an error.
            statusMessage = "CONNECTING… DESKY WILL JOIN YOUR NETWORK"
            didProvision = true
        }
    }
}

// MARK: - Password sheet model

private struct PasswordTarget: Identifiable {
    let id = UUID()
    let network: WiFiNetwork
}

// MARK: - Main view

struct WiFiSetupView: View {
    @State private var vm = WiFiSetupViewModel()
    @State private var passwordTarget: PasswordTarget? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Status / instruction banner
                statusBanner

                // Network list or scanning state
                if vm.isScanning {
                    scanningView
                } else if vm.networks.isEmpty {
                    emptyView
                } else {
                    networkList
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .task { await vm.scan() }
        .sheet(item: $passwordTarget) { target in
            PasswordSheet(network: target.network) { pwd in
                passwordTarget = nil
                Task { await vm.connect(ssid: target.network.ssid, password: pwd) }
            }
        }
    }

    // MARK: - Status banner

    @ViewBuilder
    private var statusBanner: some View {
        if let msg = vm.statusMessage {
            HStack(spacing: 10) {
                Rectangle()
                    .fill(vm.didProvision ? Theme.green : Theme.pink)
                    .frame(width: 6, height: 6)
                Text(msg)
                    .font(.pressStart(7))
                    .foregroundColor(vm.didProvision ? Theme.green : Theme.pink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(14)
            .background(
                (vm.didProvision ? Theme.green : Theme.pink).opacity(0.08)
            )
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor((vm.didProvision ? Theme.green : Theme.pink).opacity(0.25)),
                alignment: .bottom
            )
        } else {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Theme.cool)
                    .frame(width: 6, height: 6)
                Text("CONNECT IPHONE TO \"DESKY-SETUP\" FIRST")
                    .font(.pressStart(6))
                    .foregroundColor(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .padding(14)
            .background(Theme.card)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Theme.line),
                alignment: .bottom
            )
        }
    }

    // MARK: - Scanning

    private var scanningView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .tint(Theme.pink)
                .scaleEffect(1.4)
            Text("SCANNING NETWORKS…")
                .font(.pressStart(8))
                .foregroundColor(Theme.muted)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("NO NETWORKS FOUND")
                .font(.pressStart(8))
                .foregroundColor(Theme.muted)
            Text("Make sure you're connected\nto the Desky-Setup hotspot")
                .font(.system(size: 13))
                .foregroundColor(Theme.dim)
                .multilineTextAlignment(.center)
            Button {
                Task { await vm.scan() }
            } label: {
                Text("RETRY")
                    .font(.pressStart(8))
                    .foregroundColor(Theme.amber)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Theme.amber.opacity(0.4), lineWidth: 1)
                    )
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Network list

    private var networkList: some View {
        ScrollView {
            VStack(spacing: 1) {
                ForEach(vm.networks) { net in
                    networkRow(net)
                }
            }
            .padding(.top, 1)
        }
    }

    private func networkRow(_ net: WiFiNetwork) -> some View {
        Button {
            passwordTarget = PasswordTarget(network: net)
        } label: {
            HStack(spacing: 14) {
                // Signal bars
                signalBars(fraction: net.signalFraction, color: net.signalColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(net.ssid)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.fg)
                    Text(net.keyed ? "SECURED" : "OPEN")
                        .font(.pressStart(5))
                        .foregroundColor(net.keyed ? Theme.muted : Theme.green)
                }

                Spacer()

                if net.keyed {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.dim)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.dim)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Theme.card)
        }
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Theme.line),
            alignment: .bottom
        )
    }

    // MARK: - Signal bars (4-bar pixel style)

    private func signalBars(fraction: Double, color: Color) -> some View {
        let heights: [CGFloat] = [4, 8, 12, 16]
        return HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(heights.enumerated()), id: \.offset) { i, h in
                let filled = fraction >= Double(i + 1) / Double(heights.count)
                Rectangle()
                    .fill(filled ? color : Theme.line)
                    .frame(width: 4, height: h)
            }
        }
        .frame(width: 22, height: 16)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text("WI-FI SETUP")
                .font(.pressStart(10))
                .foregroundColor(Theme.fg)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                Task { await vm.scan() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(vm.isScanning ? Theme.dim : Theme.amber)
            }
            .disabled(vm.isScanning)
        }
    }
}

// MARK: - Previews

#Preview("Wi-Fi Setup") {
    NavigationStack { WiFiSetupView() }
}

// MARK: - Password sheet

private struct PasswordSheet: View {
    let network: WiFiNetwork
    let onConnect: (String) -> Void

    @State private var password = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: "080808").ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    // SSID header
                    VStack(spacing: 8) {
                        Image(systemName: "wifi")
                            .font(.system(size: 28))
                            .foregroundColor(Theme.cool)
                        Text(network.ssid)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Theme.fg)
                            .lineLimit(1)
                        Text("ENTER WI-FI PASSWORD")
                            .font(.pressStart(6))
                            .foregroundColor(Theme.muted)
                    }

                    // Password field
                    SecureField("Password", text: $password)
                        .font(.system(size: 16))
                        .foregroundColor(Theme.fg)
                        .padding(14)
                        .background(Theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.line, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.horizontal, 2)

                    // Connect button
                    Button {
                        let pwd = password
                        dismiss()
                        onConnect(pwd)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                            Text("PROVISION DESKY")
                                .font(.pressStart(8))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(network.keyed && password.isEmpty)
                    .opacity(network.keyed && password.isEmpty ? 0.4 : 1)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 20)
        }
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.hidden) // using custom handle above
    }
}
