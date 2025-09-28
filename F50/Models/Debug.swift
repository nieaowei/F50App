//
//  Debug.swift
//  F50
//
//  Created by Nekilc on 2025/9/28.
//

import Foundation

nonisolated struct NeighborCellInfo: Codable, Equatable, Identifiable {
    var id: String {
        "\(band.value):\(earfcn.value):\(pci.value)"
    }

    let band, earfcn, pci, rsrp: StringInt
    let rsrq, sinr: StringInt
}

nonisolated struct LockedCellInfo: Codable, Equatable, Identifiable {
    var id: String {
        "\(earfcn.value):\(pci.value)"
    }

    let earfcn, pci, rat: StringInt
}

struct AdvantedSettings: AutoCmds, Equatable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case lte_band_lock
        case nr_band_lock
        case neighbor_cell_info
        case locked_cell_info
    }

    private let lte_band_lock: String
    private let nr_band_lock: String

    let neighbor_cell_info: [NeighborCellInfo]
    let locked_cell_info: [LockedCellInfo]

    var lockedLTE: [LTEBand] {
        lte_band_lock.split(separator: ",")
            .map { sub in
                LTEBand(rawValue: Int(sub)!)!
            }
    }

    var lockedNR: [NRBand] {
        nr_band_lock.split(separator: ",")
            .map { sub in
                NRBand(rawValue: Int(sub)!)!
            }
    }
}

struct SetLTEBandLock: Setter {
    private var lte_band_lock: String = ""

    static func goformid() -> GoFormIds {
        .LTE_BAND_LOCK
    }

    mutating func appendBand(_ band: LTEBand) {
        if lte_band_lock.isEmpty {
            lte_band_lock += "\(band.rawValue)"
        } else {
            lte_band_lock += ",\(band.rawValue)"
        }
    }
}

struct SetNRBandLock: Setter {
    private var nr_band_lock: String = ""

    static func goformid() -> GoFormIds {
        .NR_BAND_LOCK
    }

    mutating func appendBand(_ band: NRBand) {
        if nr_band_lock.isEmpty {
            nr_band_lock += "\(band.rawValue)"
        } else {
            nr_band_lock += ",\(band.rawValue)"
        }
    }
}

struct SetCellLock: Setter {
    let earfcn, pci, rat: StringInt

    static func goformid() -> GoFormIds {
        .CELL_LOCK
    }
}
