//
//  StationMg.swift
//  F50
//
//  Created by Nekilc on 2025/9/25.
//

import SwiftUI
import OSLog

struct StationMgScreen: View {
    @Environment(GlobalStore.self) var g: GlobalStore

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
            Section("Access Devices") {
                Table(of: MergedStationInfo.self) {
                    TableColumn("Host Name", value: \.hostname)
                    TableColumn("MAC Address", value: \.mac_addr)
                    TableColumn("Access Method") { sta in
                        if sta.isWifi {
                            Text("Wi-Fi")
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
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                g.refreshStationInfo()
                g.refreshAccessControlInfo()
            }
        }
    }

    func addBlack(_ name: String, _ mac: String) {
        Logger.ui.debug("Adding \(name) (\(mac)) to blacklist")
        guard var accessControlInfo = g.accessControlInfo else {
            Logger.ui.error("Cannot add to blacklist: access control info not loaded")
            return
        }
        accessControlInfo.appendBlack(name, mac)

        Task {
            let resp: Result<DefaultResp, Error> = await accessControlInfo.set(g.zteSvc)
            if case .success(let data) = resp, data.result.rawValue {
                Logger.ui.info("\(name) (\(mac)) added to blacklist")
                g.refreshAccessControlInfo()
                g.refreshStationInfo()
            } else if case .failure(let err) = resp {
                Logger.ui.error("Failed to add \(name) to blacklist: \(err.localizedDescription)")
            }
        }
    }

    func removeBlack(_ name: String, _ mac: String) {
        Logger.ui.debug("Removing \(name) (\(mac)) from blacklist")
        guard var accessControlInfo = g.accessControlInfo else {
            Logger.ui.error("Cannot remove from blacklist: access control info not loaded")
            return
        }
        accessControlInfo.removeBlack(mac)
        Task {
            let resp: Result<DefaultResp, Error> = await accessControlInfo.set(g.zteSvc)
            if case .success(let data) = resp, data.result.rawValue {
                Logger.ui.info("\(name) (\(mac)) removed from blacklist")
                g.refreshAccessControlInfo()
                g.refreshStationInfo()
            } else if case .failure(let err) = resp {
                Logger.ui.error("Failed to remove \(name) from blacklist: \(err.localizedDescription)")
            }
        }
    }
}
