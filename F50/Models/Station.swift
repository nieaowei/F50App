//
//  Station.swift
//  F50
//
//  Created by Nekilc on 2025/9/25.
//

import Foundation

// lan_station_list
// station_list
struct StationInfo: Codable, Identifiable {
    var id: String {
        mac_addr
    }

    let mac_addr: String
    let hostname: String
    let ip_addr: String
}

struct MergedStationInfo: Identifiable {
    var id: String {
        mac_addr
    }

    let mac_addr: String
    let hostname: String
    let ip_addr: String
    let isWifi: Bool
}

struct StationList: AutoCmds {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case station_list
        case lan_station_list
    }

    let station_list: [StationInfo]
    let lan_station_list: [StationInfo]

    static func get(zteSvc: ZTEService) async throws -> StationList {
        let decoded: StationList = try await Task.detached {
            try await zteSvc.get_cmd_by_keys().0
        }.value
        return decoded
//        try await zteSvc.get_cmd_by_keys().0
    }

    var merged: [MergedStationInfo] {
        station_list.map { MergedStationInfo(mac_addr: $0.mac_addr, hostname: $0.hostname, ip_addr: $0.ip_addr, isWifi: true) } +
            lan_station_list.map { MergedStationInfo(mac_addr: $0.mac_addr, hostname: $0.hostname, ip_addr: $0.ip_addr, isWifi: false) }
    }
}

//
// {
//    "AclMode": "2",
//    "WhiteMacList": "",
//    "BlackMacList": "2e:2c:d4:dd:d2:c2;2e:2c:d4:dd:d2:c1;",
//    "WhiteNameList": "",
//    "BlackNameList": "test2;test1;"
// }

struct QueryDeviceAccessControlList: Setter, Decodable {
    static func goformid() -> GoFormIds {
        .setDeviceAccessControlList
    }

    let AclMode: String
    private var WhiteMacList: String
    private var BlackMacList: String
    private var WhiteNameList: String
    private var BlackNameList: String

    func whiteMacList() -> [String] {
        WhiteMacList.split(separator: ";").map { String($0) }
    }

    func whiteNameList() -> [String] {
        WhiteNameList.split(separator: ";").map { String($0) }
    }

    func blackMacList() -> [String] {
        BlackMacList.split(separator: ";").map { String($0) }
    }

    func blackNameList() -> [String] {
        BlackNameList.split(separator: ";").map { String($0) }
    }

    mutating func appendBlack(_ name: String, _ mac: String) {
        BlackNameList += name + ";"
        BlackMacList += mac + ";"
    }

    mutating func removeBlack(_ mac: String) {
        var blackMacList = blackMacList()
        guard let index = blackMacList.firstIndex(of: mac) else {
            return
        }
        blackMacList.remove(at: index)
        BlackMacList = blackMacList.joined(separator: ";")
        var blackNameList = blackNameList()
        blackNameList.remove(at: index)
        BlackNameList = blackNameList.joined(separator: ";")
    }

    mutating func appendWhite(_ name: String, _ mac: String) {
        WhiteNameList += name + ";"
        WhiteMacList += mac + ";"
    }

    func toBlackStationList() -> [StationInfo] {
        zip(blackNameList(), blackMacList())
            .map { name, mac in
                StationInfo(mac_addr: mac, hostname: name, ip_addr: "")
            }
    }

    func toWhiteStationList() -> [StationInfo] {
        zip(whiteNameList(), whiteMacList())
            .map { name, mac in
                StationInfo(mac_addr: mac, hostname: name, ip_addr: "")
            }
    }

    static func get(zteSvc: ZTEService) async throws -> QueryDeviceAccessControlList {
        try await zteSvc.get_cmd(cmds: [.queryDeviceAccessControlList]).0
    }
}
