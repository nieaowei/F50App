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

    @State var ipaddr: String = ""
    @State var subMask: String = ""
    @State var poolStart: String = ""
    @State var poolEnd: String = ""
    @State var lease: UInt64 = 0
    var body: some View {
        Form {
            Section("Router Settings") {
                TextField("IP Address", text: $ipaddr,)
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
                Toggle("Indicator Light", isOn: .constant(true))
                Picker("USB Internet Protocol", selection: .constant("Auto")) {
                    Text(verbatim: "Auto").tag("Auto")
                    Text(verbatim: "RNDIS").tag("RNDIS")
                    Text(verbatim: "CDC-ECM").tag("CDC-ECM")
                }
                .pickerStyle(.radioGroup)
                Toggle("File Sharing", isOn: .constant(false))
            }
        }
        .formStyle(.grouped)
        .task {
            g.refreshDHCPSettings()
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
    }
}
