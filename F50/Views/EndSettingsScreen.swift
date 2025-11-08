//
//  EndSettingsScreen.swift
//  F50
//
//  Created by Nekilc on 2025/9/21.
//

import SwiftUI

struct EndSettingsScreen: View {
    @Environment(GlobalStore.self) var g: GlobalStore

    var info: DHCPSettings? {
        g.dhcpSettings
    }

    var deviceSettings: DeviceSettings? {
        g.deviceSettings
    }

    @State var ipaddr: String = ""
    @State var subMask: String = ""
    @State var poolStart: String = ""
    @State var poolEnd: String = ""
    @State var lease: UInt64 = 0

    @State var usbProtocal: USBNetworkProtocal = .Auto
    @State var indicator: Bool = true
    @State var fileShare: Bool = false
    var body: some View {
        Form {
            Section("Router Settings") {
                TextField("IP Address", text: $ipaddr)
                TextField("Subnet Mask", text: $subMask)
                Toggle("DHCP Server", isOn: .constant(true))
                LabeledContent("DHCP IP Pool") {
                    HStack {
                        TextField("", text: $poolStart)
                        Text(verbatim: "-")
                        TextField("", text: $poolEnd)
                    }
                }
                TextField("DHCP Lease Time", value: $lease, format: .number)
            }
            .sectionActions {
                Button("Apply") {}
            }

            Section("Other Settings") {
                Toggle("Indicator Light", isOn: $indicator)
                    .onChange(of: indicator) { _, newValue in
                        updateIndicator(newValue)
                    }
                Picker("USB Internet Protocol", selection: $usbProtocal) {
                    ForEach(USBNetworkProtocal.allCases) { up in
                        Text(up.localizedString).tag(up)
                    }
                }
                .pickerStyle(.radioGroup)
                Toggle("File Sharing", isOn: $fileShare)
            }
        }
        .formStyle(.grouped)
        .task {
            g.refreshDHCPSettings()
            g.refreshDeviceSettings()
        }
        .task(id: g.dhcpSettings) {
            if let info {
                ipaddr = info.lan_ipaddr.stringValue
                poolStart = info.dhcpStart.stringValue
                poolEnd = info.dhcpEnd.stringValue
                subMask = info.lan_netmask.stringValue
                var dhcpLease = info.dhcpLease_hour
                dhcpLease.removeLast()
                lease = UInt64(dhcpLease)!
            }
        }
        .task(id: g.deviceSettings) {
            if let deviceSettings {
                indicator = deviceSettings.indicator_light_switch.rawValue
                fileShare = deviceSettings.samba_switch.rawValue
                usbProtocal = deviceSettings.usb_network_protocal
            }
        }
    }

    func updateIndicator(_ status: Bool) {
        Task {
            _ = try await SetIndicatorSwitch(indicator_light_switch: status.u8).set(g.zteSvc)
        }
    }
}
