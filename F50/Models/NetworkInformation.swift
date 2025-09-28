//
//  NetworkInformation.swift
//  F50
//
//  Created by Nekilc on 2025/9/22.
//

import Foundation
import SwiftUI

enum LTEBand: Int, CaseIterable, Codable, Identifiable {
    var id: Int {
        rawValue
    }

    case band1 = 1
    case band3 = 3
    case band5 = 5
    case band8 = 8
    case band34 = 34
    case band38 = 38
    case band39 = 39
    case band40 = 40
    case band41 = 41
}

enum NRBand: Int, CaseIterable, Codable, Identifiable {
    var id: Int {
        rawValue
    }

    case band1 = 1
    case band5 = 5
    case band8 = 8
    case band28 = 28
    case band41 = 41
    case band78 = 78
}

enum NetworkType: String, Codable, CaseIterable {
    // 2G
    case GSM
    case GPRS
    case EDGE

    // 3G
    case UMTS
    case HSDPA
    case HSUPA
    case HSPA
    case HSPAPlus = "HSPA+"
    case DC
    case DCHSPA = "DC-HSPA"
    case DCHSPAPlus = "DC-HSPA+"
    case DCHSDPA = "DC-HSDPA"

    // 4G
    case LTE
    case LTECA = "LTE_CA"
    case LTEA = "LTE_A"
    case LTENSA = "LTE-NSA"
    case EHRPD

    // 5G
    case ENDC
    case SA
    case _5G = "5G"
}

extension NetworkType {
    var is2G: Bool {
        switch self {
        case .GSM, .GPRS, .EDGE: return true
        default: return false
        }
    }

    var is3G: Bool {
        switch self {
        case .UMTS, .HSDPA, .HSUPA, .HSPA, .HSPAPlus, .DC, .DCHSPA, .DCHSPAPlus, .DCHSDPA:
            return true
        default: return false
        }
    }

    var is4G: Bool {
        switch self {
        case .LTE, .LTECA, .LTEA, .LTENSA, .EHRPD: return true
        default: return false
        }
    }

    var is5G: Bool {
        switch self {
        case .ENDC, .SA, ._5G: return true
        default: return false
        }
    }
}

extension NetworkType {
    var localizedString: LocalizedStringKey {
        if is2G { return LocalizedStringKey("2G") }
        else if is3G { return LocalizedStringKey("3G") }
        else if is4G { return LocalizedStringKey("4G") }
        else if is5G { return LocalizedStringKey("5G") }
        else { return LocalizedStringKey("Unknown") }
    }
}

// struct NetworkInfo {
//    let fcn: Int
//    let bands: Int
//    let bands_widths: Int
//    let pci: Int
//    let cell_id: Int
//    let signal_strength: Int
//    let snr: Int
//    let rsrp: Int
//    let rsrq: Int
//    let rssi: Int
//
//    init(fcn: Int?, bands: Int?, bands_widths: Int?, pci: Int?, cell_id: Int?, signal_strength: Int?, snr: Int?, rsrp: Int?, rsrq: Int?, rssi: String?) {
//        self.fcn = fcn ?? 0
//        self.bands = bands ?? 0
//        self.bands_widths = bands_widths ?? 0
//        self.pci = pci ?? 0
//        self.cell_id = cell_id ?? 0
//        self.signal_strength = signal_strength ?? 0
//        self.snr = snr ?? 0
//        self.rsrp = rsrp ?? 0
//        self.rsrq = rsrq ?? 0
//        self.rssi = Int(rssi ?? "0") ?? 0
//    }
// }

struct NetworkInformation: Codable {
    let Nr_fcn: Int?
    let Nr_pci: Int?
    let Nr_bands: NRBand?
    let Nr_band_widths: String? // 原始 JSON 为空字符串
    let Nr_cell_id: UInt64?
    let Nr_signal_strength: Int?
    let Nr_snr: Int?
    let nr_rsrp: Int?
    let nr_rsrq: Int?
    let nr_rssi: String? // 原始 JSON 为空字符串

    let Lte_fcn: Int?
    let Lte_bands: LTEBand?
    let Lte_bands_widths: Int?
    let Lte_pci: Int?
    let Lte_cell_id: Int?
    let Lte_signal_strength: Int?
    let Lte_snr: Int?
    let lte_rsrp: Int?
    let lte_rsrq: Int?
    let lte_rssi: Int?

    let network_type: Int
    let Lte_ca_status: StringBool

//    var current: NetworkInfo {
//        if network_type.is5G {
//            NetworkInfo(fcn: Nr_fcn, bands: Nr_bands, bands_widths: Nr_band_widths, pci: Nr_pci, cell_id: Nr_cell_id, signal_strength: Nr_signal_strength, snr: Nr_snr, rsrp: nr_rsrp, rsrq: nr_rsrq, rssi: nr_rssi)
//        } else {}
//    }

    static func get(_ zteSvc: ZTEService) async throws -> NetworkInformation {
        try await zteSvc.get_cmd(cmds: [.network_information, .Lte_ca_status]).0
    }
}
