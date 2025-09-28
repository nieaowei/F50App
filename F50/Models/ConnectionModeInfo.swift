//
//  ConnectionModeInfo.swift
//  F50
//
//  Created by Nekilc on 2025/9/26.
//

import Foundation
import SwiftUI

enum ConnectionMode: String, Codable, CaseIterable, Identifiable {
    var id: String { self.rawValue }

    case Auto = "auto_dial"
    case Manual = "manual_dial"

    var localizedString: LocalizedStringKey {
        switch self {
        case .Auto: return LocalizedStringKey("Auto")
        case .Manual: return LocalizedStringKey("Manual")
        }
    }
}

struct ConnectionModeInfo: Decodable, Equatable {
    let connectionMode: ConnectionMode
    let autoConnectWhenRoaming: StringBool // on off

    static func get(zteSvc: ZTEService) async throws -> ConnectionModeInfo {
        try await zteSvc.get_cmd(cmds: [.ConnectionMode]).0
    }
}

struct SetConnectionMode: Setter {
    static func goformid() -> GoFormIds {
        .SET_CONNECTION_MODE
    }
    
    let connectionMode: ConnectionMode
    let roam_setting_option: StringBool // on off

}

enum BearerPreference: String, Codable, CaseIterable, Identifiable {
    var id: String { self.rawValue }
    case All = "WL_AND_5G"
    case Only5GNSA = "LTE_AND_5G"
    case Only5GSA = "Only_5G"
    case And4G3G = "WCDMA_AND_LTE"
    case Only4G = "Only_LTE"
    case Only3G = "Only_WCDMA"

    var localizedString: LocalizedStringKey {
        switch self {
        case .All:
            LocalizedStringKey("5G/4G/3G")
        case .Only5GNSA:
            LocalizedStringKey("5G NSA")
        case .Only5GSA:
            LocalizedStringKey("5G SA")
        case .And4G3G:
            LocalizedStringKey("4G/3G")
        case .Only4G:
            LocalizedStringKey("4G")
        case .Only3G:
            LocalizedStringKey("3G")
        }
    }
}

struct SetBearerPreference: Setter {
    static func goformid() -> GoFormIds {
        .SET_BEARER_PREFERENCE
    }
    
    let BearerPreference: BearerPreference

}

 struct CellularSettings: AutoCmds, Equatable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case net_select
    }

    let net_select: BearerPreference

    static func get(zteSvc: ZTEService) async throws -> CellularSettings {
        try await zteSvc.get_cmd_by_keys().0
    }
}
