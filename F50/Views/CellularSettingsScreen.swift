//
//  CellularSettingsScreen.swift
//  F50
//
//  Created by Nekilc on 2025/9/26.
//

import SwiftUI

struct CellularSettingsScreen: View {
    @Environment(GlobalStore.self) private var g: GlobalStore
    
    private var connInfo: ConnectionModeInfo? {
        g.connectionModeInfo
    }
    
    private var cellInfo: CellularSettings? {
        g.cellularSettings
    }
    
    @State private var connMode: ConnectionMode = .Auto
    @State private var roamingEnabled: Bool = false
    @State private var netSelect: BearerPreference = .All
    
    var body: some View {
        Form {
            Section("连接模式") {
                Picker("连接模式", selection: $connMode) {
                    ForEach(ConnectionMode.allCases) { mod in
                        Text(mod.localizedString).tag(mod)
                    }
                }
                if connMode == .Auto {
                    Toggle("漫游时自动连接", isOn: $roamingEnabled)
                }
            }
            .sectionActions {
                Button("Apply") {
                    updateConnectionMode()
                }
            }
            Section("网络模式") {
                Picker("网络模式", selection: $netSelect) {
                    ForEach(BearerPreference.allCases) { mod in
                        Text(mod.localizedString).tag(mod)
                    }
                }
            }
            .sectionActions {
                Button("Apply") {
                    updateNetworkMode()
                }
            }
//            Section("APN") {} // TODO
        }
        .formStyle(.grouped)
        .task {
            g.refreshConnectionModeInfo()
            g.refreshCellularSettings()
        }
        .task(id: g.connectionModeInfo) {
            if let connInfo {
                connMode = connInfo.connectionMode
                roamingEnabled = connInfo.autoConnectWhenRoaming.rawValue
            }
         }
        .task(id: g.cellularSettings) {
            if let cellInfo {
                netSelect = cellInfo.net_select
            }
        }
    }
    
    func updateConnectionMode() {
        let p = SetConnectionMode(connectionMode: connMode, roam_setting_option: roamingEnabled ? .OnTrue : .OffFalse)
        Task {
            try await p.set(g.zteSvc)
        }
    }
    
    func updateNetworkMode() {
        let p = SetBearerPreference(BearerPreference: netSelect)
        Task {
            try await p.set(g.zteSvc)
        }
    }
}
