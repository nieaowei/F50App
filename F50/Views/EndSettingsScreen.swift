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
    @State var lease: String = ""
    var body: some View {
        Form {
            Section("路由设置") {
                TextField("IP地址", text: $ipaddr)
                TextField("子网掩码", text: $subMask)
                Toggle("DHCP服务", isOn: .constant(true))
                LabeledContent("DHCP IP池") {
                    HStack {
                        TextField("", text: $poolStart)
                        Text(verbatim: "-")
                        TextField("", text: $poolEnd)
                    }
                }
                TextField("DHCP租期", text: $lease)
            }
            .sectionActions {
                Button("Apply") {}
            }

            Section("USB上网设置") {
                Toggle("指示灯设置", isOn: .constant(true))
                Picker("USB上网协议", selection: .constant("Auto")) {
                    Text(verbatim: "Auto").tag("Auto")
                    Text(verbatim: "RNDIS").tag("RNDIS")
                    Text(verbatim: "CDC-ECM").tag("CDC-ECM")
                }
                .pickerStyle(.radioGroup)
            }

            Section("文件共享") {
                Toggle("文件共享", isOn: .constant(false))
            }
        }
        .formStyle(.grouped)
        .task {
            do {
                try await g.refreshDHCPSettings()
            } catch {}
        }
        .task(id: g.dhcpSettings) {
            if let info {
                ipaddr = info.lan_ipaddr.stringValue
                poolStart = info.dhcpStart.stringValue
                poolEnd = info.dhcpEnd.stringValue
                subMask = info.lan_netmask.stringValue
                lease = info.dhcpLease_hour
            }
        }
    }
}
