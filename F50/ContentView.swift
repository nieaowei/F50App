//
//  ContentView.swift
//  F50
//
//  Created by Nekilc on 2025/9/21.
//

import SwiftUI
import OSLog

struct ContentView: View {
    @Environment(GlobalStore.self) private var g: GlobalStore

    var body: some View {
        NavigationSplitView {
            List {
                Section("Basic") {
                    NavigationLink("Dashboard") {
                        DashboardScreen()
                    }
                    NavigationLink("Network Info") {
                        NetworkInfoScreen()
                    }
                    NavigationLink("Access Devices") {
                        StationMgScreen()
                    }
                }
                Section("Network Settings") {
                    NavigationLink("Wi-Fi") {
                        WifiSettingsScreen()
                    }
                    NavigationLink("Cellular") {
                        CellularSettingsScreen()
                    }
                }
                Divider()
                NavigationLink("SMS") {
                    SmsScreen()
                }
                NavigationLink("End Settings") {
                    EndSettingsScreen()
                }
                NavigationLink("Traffic Management") {
                    VolumeMgScreen()
                }
                NavigationLink("Advanced Settings") {
                    AdvantedSettingsScreen()
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif

        } detail: {
            DashboardScreen()
        }
        .toolbar {
            ToolbarView(g: g)
            Spacer()

            Button("Reboot", systemImage: "power") {
                Task {
                    Logger.ui.info("Reboot requested by user")
                    _ = await Reboot().set(g.zteSvc)
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

struct ToolbarView: View {
    let g: GlobalStore

    init(g: GlobalStore) {
        self.g = g
    }

    @State var pppStatus: Bool = false

    var body: some View {
        HStack {
            HStack {
                VStack {
                    Image(systemName: "arrow.up")
                    Image(systemName: "arrow.down")
                }
                VStack {
                    Text(verbatim: (g.toolbar?.realtime_tx_thrpt ?? 0).displayByteCount + "/s")
                    Text(verbatim: (g.toolbar?.realtime_rx_thrpt ?? 0).displayByteCount + "/s")
                }
            }
            .controlSize(.mini)
            .frame(width: 60, alignment: .leading)

            Text(verbatim: "\(g.toolbar?.network_type.rawValue ?? "")")
            Text(verbatim: "\(g.toolbar?.network_provider ?? "")")
            Image(systemName: "cellularbars", variableValue: Double(g.toolbar?.signalbar ?? 0) / 5)

            Toggle("", isOn: $pppStatus)
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .padding(.horizontal)
        .task {
            g.refreshToolbar()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                g.refreshToolbar()
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(300))
                g.refreshLogin(password: "")
            }
        }
        .task(id: g.toolbar?.ppp_status) {
            if let sta = g.toolbar?.ppp_status {
                pppStatus = sta.isConnected()
            }
        }
        .onChange(of: pppStatus) { _, newValue in
            Task {
                _ = await (newValue ? SetConnectNetwork().set(g.zteSvc) : SetDisconnectNetwork().set(g.zteSvc))
            }
        }
    }
}

#Preview {
    ContentView()
}
