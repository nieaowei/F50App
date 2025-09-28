//
//  PPPStatus.swift
//  F50
//
//  Created by Nekilc on 2025/9/28.
//

import Foundation

enum PPPStatus: String, Codable {
    case ppp_disconnected
    case ppp_connecting
    case ppp_disconnecting
    case ppp_connected
    case ipv6_connected
    case ipv4_ipv6_connected

    func isConnected() -> Bool {
        switch self {
        case .ppp_connected, .ipv4_ipv6_connected, .ipv6_connected:
            return true
        default:
            return false
        }
    }
}
