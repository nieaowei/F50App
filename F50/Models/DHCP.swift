//
//  DHCP.swift
//  F50
//
//  Created by Nekilc on 2025/9/27.
//

import Foundation

struct SetDHCPSettings: Setter {
    static func goformid() -> GoFormIds {
        .DHCP_SETTING
    }

    let lanIp: String
    let lanNetmask: String
    let lanDhcpType: String
    let dhcpStart: String
    let dhcpEnd: String
    let dhcpLease: String
    let dhcp_reboot_flag: String
    let mac_ip_reset: String
}

struct DHCPSettings: AutoCmds, Equatable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case mac_address
        case lan_netmask
        case dhcpStart
        case dhcpEnd
        case dhcpLease_hour
        case tcp_mss
        case mtu
        case lan_ipaddr
    }

    let mac_address: MACAddress
    let lan_netmask: IPAddress
    let dhcpStart: IPAddress
    let dhcpEnd: IPAddress
    let dhcpLease_hour: String // xH
    let tcp_mss: StringUInt64
    let mtu: StringUInt64
    let lan_ipaddr: IPAddress
    
}
