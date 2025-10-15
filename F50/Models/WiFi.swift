//
//  WiFi.swift
//  F50
//
//  Created by Nekilc on 2025/9/26.
//

import SwiftUI

enum WiFiModuleSwitch: String, Codable, CaseIterable, Identifiable, Equatable {
    var id: String {
        rawValue
    }

    case Chip2_4 = "0"
    case Chip5 = "1"
    case Off

    var localizedString: LocalizedStringKey {
        switch self {
        case .Chip2_4:
            LocalizedStringKey("2.4 GHz")
        case .Chip5:
            LocalizedStringKey("5 GHz")
        case .Off:
            LocalizedStringKey("Off")
        }
    }
}

struct AccessPointInfoResp: Decodable, Equatable {
    private let WiFiModuleSwitch: StringBool
    private let ResponseList: [AccessPointInfo]

    var current: AccessPointInfo? {
        self.ResponseList.first { ac in
            ac.AccessPointSwitchStatus.rawValue
        }
    }

    static func get(zteSvc: ZTEService) async throws -> AccessPointInfoResp {
        try await zteSvc.get_cmd(cmds: [.queryAccessPointInfo, .queryWiFiModuleSwitch]).0
    }
}

struct AccessPointInfo: Decodable, Equatable {
    let ChipIndex: String
    let AccessPointIndex: String
    let AccessPointSwitchStatus: StringBool
    let SSID: String
    let ApMaxStationNumber: UInt64
//    let ApIsolate: String
    let AuthMode: AuthMode
//    let EncrypType: String
    let Password: String
    let Pmf_switch: Bool
//    let PasswordShow: String
//    let QrImageUrl: String
//    let QrImageShow: String
    let ApBroadcastDisabled: StringBool
//    let CurrentStationNumber: String
    let CountryCode: String
//    let WirelessMode: String
//    let Channel: String
//    let ChannelRange: String
//    let BandWidth: String
//    let GuestSSIDActiveTime: String
//    let Band: String
}

enum ChipEnum: String, CaseIterable, Codable {
    case Chip2_4 = "chip1"
    case Chip5 = "chip2"
}

struct SetSwitchWiFiChip: Setter {
    static func goformid() -> GoFormIds {
        .switchWiFiChip
    }

    let ChipEnum: ChipEnum
    let GuestEnable: UInt8Bool
}

struct SetSwitchWiFiModule: Setter {
    static func goformid() -> GoFormIds {
        .switchWiFiModule
    }
    let SwitchOption: UInt8Bool
}

enum AuthMode: String, CaseIterable, Codable, Identifiable, Equatable {
    var id: String {
        rawValue
    }

    case OPEN
    case WPA2PSK
    case WPA2PSKWPA3PSK
    case WPA3PSK
    
    var localizedString: LocalizedStringKey{
        switch self {
        case .OPEN:
            "OPEN"
        case .WPA2PSK:
            "WPA2-PSK"
        case .WPA2PSKWPA3PSK:
            "WPA2-PSK/WPA3-PSK"
        case .WPA3PSK:
            "WPA3-PSK"
        }
    }
    
    
}

struct SetAccessPointInfo: Setter {
//    let ChipIndex: UInt64
//    let AccessPointIndex: UInt64
    let SSID: String
//    let ApIsolate: UInt64
    let AuthMode: AuthMode
    let ApBroadcastDisabled: UInt8Bool
    let ApMaxStationNumber: UInt64
//    let EncrypType: String
    let Password: String

    static func goformid() -> GoFormIds {
        .setAccessPointInfo
    }
}
