//
//  StationMg.swift
//  F50
//
//  Created by Nekilc on 2025/9/25.
//

import SwiftUI
internal import Combine

struct StationMgScreen: View {
    @Environment(GlobalStore.self) var g: GlobalStore

    var timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var info: StationList? {
        g.stationInfo
    }

    var accessInfo: QueryDeviceAccessControlList? {
        g.accessControlInfo
    }

    var blackStationList: [StationInfo] {
        accessInfo?.toBlackStationList() ?? []
    }

    var body: some View {
        Form {
            Section("接入设备") {
                Table(of: MergedStationInfo.self) {
                    TableColumn("Host Name", value: \.hostname)
                    TableColumn("MAC Address", value: \.mac_addr)
                    TableColumn("Access Method") { sta in
                        if sta.isWifi {
                            Text("WiFi")
                        } else {
                            Text("LAN")
                        }
                    }

                    TableColumn("IP Address", value: \.ip_addr)
                    TableColumn("Operation") { sta in
                        Button("Block") {
                            addBlack(sta.hostname, sta.mac_addr)
                        }
                        .foregroundStyle(.red)
                    }
                } rows: {
                    ForEach(info?.merged ?? []) { sta in
                        TableRow(sta)
                    }
                }
            }
            Section {
                Table(of: StationInfo.self) {
                    TableColumn("Host Name", value: \.hostname)
                    TableColumn("MAC Address", value: \.mac_addr)
                    TableColumn("Operation") { sta in
                        Button("Remove") {
                            removeBlack(sta.hostname, sta.mac_addr)
                        }
                        .foregroundStyle(.tint)
                    }
                } rows: {
                    ForEach(blackStationList) { sta in
                        TableRow(sta)
                    }
                }
            } header: {
                HStack {
                    Text("Block List")
                    Spacer()
//                    Button("新增") {
//
//                    }
                }
            }
        }
        .formStyle(.grouped)
        .task {
            g.refreshStationInfo()
            g.refreshAccessControlInfo()
        }
        .onReceive(timer) { _ in
            g.refreshStationInfo()
            g.refreshAccessControlInfo()
        }
    }

    func addBlack(_ name: String, _ mac: String) {
        guard var accessControlInfo = g.accessControlInfo else {
            return
        }
        accessControlInfo.appendBlack(name, mac)

        Task {
            let resp = try await accessControlInfo.set(g.zteSvc)

            if resp.result.rawValue {
                g.refreshAccessControlInfo()
                g.refreshStationInfo()
            }
        }
    }

    func removeBlack(_ name: String, _ mac: String) {
        guard var accessControlInfo = g.accessControlInfo else {
            return
        }
        accessControlInfo.removeBlack(mac)
        Task {
            let resp = try await accessControlInfo.set(g.zteSvc)

            if resp.result.rawValue {
                g.refreshAccessControlInfo()
                g.refreshStationInfo()
            }
        }
    }
}
