//
//  WifiSettingsScreen.swift
//  F50
//
//  Created by Nekilc on 2025/9/21.
//

import SwiftUI
import OSLog

struct WifiSettingsScreen: View {
    @Environment(GlobalStore.self) var g: GlobalStore

    var wifiSettings: AccessPointInfoResp? {
        g.wifiSettings
    }

    @State private var wifiSwitch: WiFiModuleSwitch = .Off
    @State private var ssid: String = ""
    @State private var authmode: AuthMode = .OPEN
    @State private var pass: String = ""
    @State private var max: UInt64 = 0
    @State private var broadcast: Bool = true
    
    @State private var showPassword = false
    
    

    var body: some View {
        Form {
            Section {
                Picker("Wi-Fi", selection: $wifiSwitch) {
                    ForEach(WiFiModuleSwitch.allCases) { typ in
                        Text(typ.localizedString)
                            .tag(typ)
                    }
                }
                .pickerStyle(.radioGroup)
            }
            .sectionActions {
                Button("Apply") {
                    updateMode()
                }
            }
            if wifiSwitch != .Off {
                Section {
                    TextField("SSID", text: $ssid)
                    Picker("Security Mode", selection: $authmode) {
                        ForEach(AuthMode.allCases) { au in
                            Text(au.localizedString).tag(au)
                        }
                    }
                    HStack {
                        if showPassword {
                            TextField("Password", text: $pass)
                                .autocorrectionDisabled(true)
                                .textContentType(.password)
                        } else {
                            SecureField("Password", text: $pass)
                                .textContentType(.password)
                        }
                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
//                        .accessibilityLabel(showPassword ? "隐藏密码" : "显示密码")
                    }

                    Picker("Max Station Number", selection: $max) {
                        ForEach(0 ... UInt64(10), id: \.self) { num in
                            Text("\(num)").tag(num)
                        }
                    }
                    Toggle("Broadcast SSID", isOn: $broadcast)
                }
                .sectionActions {
                    Button("Apply") {
                        updateInfo()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task {
            g.refreshWifiSettings()
        }
        .task(id: g.wifiSettings) {
            if let wifiSettings, let current = wifiSettings.current {
                ssid = current.SSID
                if let data = Data(base64Encoded: current.Password),
                   let decoded = String(data: data, encoding: .utf8)
                {
                    pass = decoded
                }
                authmode = current.AuthMode
                max = current.ApMaxStationNumber
                wifiSwitch = WiFiModuleSwitch(rawValue: current.ChipIndex) ?? .Off
                broadcast = !current.ApBroadcastDisabled.rawValue
            }
        }
    }

    func updateMode() {
        Logger.ui.debug("Updating WiFi mode to \(self.wifiSwitch.rawValue)")
        Task {
            if wifiSwitch == .Off {
                _ = await SetSwitchWiFiModule(SwitchOption: false).set(g.zteSvc)
                Logger.ui.info("WiFi turned off")
            } else if wifiSwitch == .Chip2_4 {
                _ = await SetSwitchWiFiChip(ChipEnum: .Chip2_4, GuestEnable: false).set(g.zteSvc)
                Logger.ui.info("WiFi switched to 2.4 GHz")
            } else {
                _ = await SetSwitchWiFiChip(ChipEnum: .Chip5, GuestEnable: false).set(g.zteSvc)
                Logger.ui.info("WiFi switched to 5 GHz")
            }
        }
    }

    func updateInfo() {
        Logger.ui.debug("Updating WiFi AP info: SSID=\(self.ssid)")
        Task {
            guard let passwordData = pass.data(using: .utf8) else { return }
            let setter = SetAccessPointInfo(SSID: ssid, AuthMode: authmode, ApBroadcastDisabled: (!broadcast).u8, ApMaxStationNumber: max, Password: passwordData.base64EncodedString())
            _ = await setter.set(g.zteSvc)
            Logger.ui.info("WiFi AP settings applied")
        }
    }
}
