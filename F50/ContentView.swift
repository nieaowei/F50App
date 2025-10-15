//
//  ContentView.swift
//  F50
//
//  Created by Nekilc on 2025/9/21.
//

import SwiftData
import SwiftUI
internal import Combine

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
        }
        .task {
            do {
                let r = try await g.login()

                print("\(r)")
            } catch {
                print("\(error)")
            }
        }
    }
}

extension Int128 {
    var displayByteCount: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB] // 限制单位
        formatter.countStyle = .binary // .decimal 也可以
        formatter.includesUnit = true
        formatter.includesCount = true
        formatter.formattingContext = .dynamic
        formatter.allowsNonnumericFormatting = false
        formatter.isAdaptive = true
        return formatter.string(for: Int128(self))!
    }
}

nonisolated extension UInt64 {
    var displayByteCount: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB] // 限制单位
        formatter.countStyle = .binary // .decimal 也可以
        formatter.includesUnit = true
        formatter.includesCount = true
        formatter.formattingContext = .dynamic
        formatter.allowsNonnumericFormatting = false
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: Int64(self))
    }

    var displayTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second] // 支持的单位
        formatter.unitsStyle = .abbreviated // 输出样式：h, m, s
        formatter.zeroFormattingBehavior = .dropAll // 不显示 0 值的单位
        return formatter.string(from: TimeInterval(self)) ?? "0s"
    }
}

struct ToolbarView: View {
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    let timer5 = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

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
        }
//        .task(id: g.toolbar?.wifi_onoff_state) {
//            wifiState = g.toolbar?.wifi_onoff_state.rawValue ?? false
//        }
        .onReceive(timer) { _ in
            g.refreshToolbar()
        }
        .onReceive(timer5) { _ in
            g.refreshLogin()
        }
        .task(id: g.toolbar?.ppp_status) {
            if let sta = g.toolbar?.ppp_status{
                pppStatus = sta.isConnected()
            }
        }
        .onChange(of: pppStatus) { _, newValue in
            Task {
                try await newValue ? SetConnectNetwork().set(g.zteSvc) : SetDisconnectNetwork().set(g.zteSvc)
            }
        }
    }
}

#Preview {
    ContentView()
}
