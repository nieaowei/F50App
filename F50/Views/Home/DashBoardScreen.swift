//
//  HomeScreen.swift
//  F50
//
//  Created by Nekilc on 2025/9/21.
//

import Charts
import SwiftUI
internal import Combine

struct DashboardScreen: View {
    @Environment(GlobalStore.self) private var g
    @Environment(\.openWindow) private var openWindow
    
    let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()

    private var dashboard: DashboardResp? {
        g.dashboard
    }

    private var dataVolume: [(name: String, volume: UInt64)] {
        guard let dashboard else {
            return []
        }
        if dashboard.overflow {
            return [
                ("Used", dashboard.used_volume),
            ]
        }
        return [
            ("Used", dashboard.used_volume),
            ("Unused", dashboard.remain_volume),
        ]
    }

    @State private var selectedName: String? = nil // 选中的扇区名

    @ViewBuilder
    func VolumeView() -> some View {
        HStack {
            Chart(dataVolume, id: \.name) { name, volume in
                SectorMark(
                    angle: .value("Value", volume),
                    innerRadius: .ratio(0.618)
                )
                .foregroundStyle(by: .value("Category", name))
            }
            .frame(width: 100, height: 100)
            .fixedSize()
            .chartLegend(.hidden)
            VStack(alignment: .leading, spacing: 6) {
                Text((dashboard?.overflow ?? false) ? "Over" : "Remain")
                    .font(.headline)
                Text(verbatim: dashboard?.displayRemainVolume ?? "")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor((dashboard?.overflow ?? false) ? .red : .green)
                Text("归零日期：") // 例如 2025-09-30
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    var body: some View {
        ScrollView {
            HStack {
                VolumeView()
                    .padding(.horizontal)
                Spacer()
                VStack {
                    Text("Access Devices")
                        .font(.headline)
                        .onTapGesture {
                            openWindow(id: "SMS")
                                
                        }
                    Text(verbatim: "5 台")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.green)
                }
                .padding(.horizontal)
                
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)

//            Divider()
            Form {
                Section("Wi-Fi信息") {
                    LabeledContent("SSID", value: dashboard?.wifi_chip1_ssid1_ssid ?? "")
                    LabeledContent("IP Address", value: g.dashboard?.lan_ipaddr ?? "")
                    LabeledContent("Max Station Number", value: "")
                }
                Section("运营商信息") {
                    LabeledContent("Phone Number", value: dashboard?.sim_imsi ?? "--")
                    LabeledContent("ICCID", value: dashboard?.iccid ?? "")
                    LabeledContent("IMEI", value: dashboard?.imei ?? "")
                    LabeledContent("IMSI", value: dashboard?.imsi ?? "")
                    LabeledContent("Signal Strength", value: dashboard?.Z5g_rsrp.description ?? "")
                    LabeledContent("WAN IP", value: dashboard?.wan_ipaddr ?? "")
                    LabeledContent("WAN IPv6", value: dashboard?.ipv6_wan_ipaddr ?? "")
                }
                Section("终端信息") {
                    LabeledContent("Version", value: g.dashboard?.cr_version ?? "")
                }
            }
            .formStyle(.grouped)
            .task {
                g.refreshDashboard()
            }
            .onReceive(timer) { _ in
                g.refreshDashboard()
            }
        }
    }
}

#Preview {
    DashboardScreen()
}
