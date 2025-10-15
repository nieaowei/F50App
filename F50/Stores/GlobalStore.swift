//
//  Global.swift
//  F50
//
//  Created by Nekilc on 2025/9/22.
//

import CryptoKit
import Observation
import SwiftUI

struct LDResp: AutoCmds {
    let LD: String
    enum CodingKeys: String, CodingKey, CaseIterable {
        case LD
    }
}

struct LoginParams: Encodable {
    private let password: String

    init(password: String, ld: String) {
        let ph = SHA256.hash(data: password.data(using: .utf8)!)
        let phHex = ph.map { String(format: "%02x", $0) }.joined().description.uppercased()
        let catH = SHA256.hash(data: (phHex + ld).data(using: .utf8)!)
        let catHex = catH.map { String(format: "%02x", $0) }.joined().description.uppercased()
        self.password = catHex
    }
}

struct LoginResp: Decodable {
    enum Code: UInt8, Decodable {
        case Ok = 0
        case Fail = 1
        case DuplicateUser = 2
        case BadPassword = 3
    }

    let result: Code
}

struct ToolbarResp: AutoCmds {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case signalbar
        case network_provider
        case network_type
        case realtime_tx_thrpt
        case realtime_rx_thrpt
        case realtime_time
        case wifi_onoff_state
        case ppp_status
    }

    let signalbar: UInt8
    let network_provider: String
    let network_type: NetworkType
    let realtime_tx_thrpt: UInt64
    let realtime_rx_thrpt: UInt64
    let realtime_time: UInt64
    let wifi_onoff_state: StringBool
    let ppp_status: PPPStatus
}

struct DashboardResp: AutoCmds {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case cr_version
        case lan_ipaddr
        case wifi_chip1_ssid1_ssid
        case wan_ipaddr
        case ipv6_wan_ipaddr
        case imsi
        case iccid
        case sim_imsi
        case imei
        case Z5g_rsrp
        case monthly_tx_bytes
        case monthly_rx_bytes
        case data_volume_limit_unit
        case data_volume_limit_size
        case monthly_time
        case wan_auto_clear_flow_data_switch
        case traffic_clear_date
        case wifi_access_sta_num
    }

    let cr_version: String
    let lan_ipaddr: String
    let wifi_chip1_ssid1_ssid: String
    let wan_ipaddr: String?
    let ipv6_wan_ipaddr: String
    let imsi: String
    let iccid: String
    let sim_imsi: String
    let imei: String
    let Z5g_rsrp: Int
    let wifi_access_sta_num: StringUInt64
//    let lan_station_list: [StationInfo]

    let monthly_tx_bytes: UInt64
    let monthly_rx_bytes: UInt64
    let data_volume_limit_unit: VolumeLimitUnit
    let data_volume_limit_size: String
    let monthly_time: UInt64

    let wan_auto_clear_flow_data_switch: StringBool // 流量清零开关 on off
    let traffic_clear_date: StringUInt64 // 清零日期

    var data_volume_limit_size_num: UInt64 {
        switch data_volume_limit_unit {
        case .Data:
            {
                let s = data_volume_limit_size
                let parts = s.split(separator: "_")
                if parts.count == 2,
                   let a = UInt64(parts[0]),
                   let b = UInt64(parts[1])
                {
                    return a * b
                }
                return 0
            }()
        case .Time:
            data_volume_limit_size.isEmpty ? 0 : UInt64(data_volume_limit_size)! * 60
        }
    }

    var total_volume: UInt64 {
        switch data_volume_limit_unit {
        case .Data:
            return data_volume_limit_size_num * 1024 * 1024
        case .Time:
            return data_volume_limit_size_num
        }
    }

    var used_volume: UInt64 {
        switch data_volume_limit_unit {
        case .Data:
            return monthly_rx_bytes + monthly_tx_bytes
        case .Time:
            return monthly_time / 60
        }
    }

    var remain_volume: UInt64 {
        overflow ? used_volume - total_volume : total_volume - used_volume
    }

    var overflow: Bool {
        total_volume < used_volume
    }

    var displayRemainVolume: String {
        switch data_volume_limit_unit {
        case .Data:
            remain_volume.displayByteCount
        case .Time:
            (remain_volume * 60).displayTime
        }
    }
}

@Observable
public class GlobalStore {
    var zteSvc: ZTEService

    @ObservationIgnored
    @AppStorage("password")
    private var password: String = ""

    public init(zteSvc: ZTEService) {
        _zteSvc = zteSvc
    }

    func login() async throws -> LoginResp {
        let ld = try await LD.get(zteSvc: zteSvc).LD
        return try await zteSvc.set_cmd(goformId: .LOGIN, params: LoginParams(password: "admin", ld: ld)).0
    }

    func refreshLogin() {
        Task {
            do {
                _ = try await self.login()
            } catch {}
        }
    }

    func toolbar() async throws -> ToolbarResp {
        return try await zteSvc.get_cmd_by_keys().0
    }

    var toolbar: ToolbarResp?

    func refreshToolbar() {
        Task {
            toolbar = try await self.toolbar()
            #if DEBUG
            print("Toolbar Refresh")
            #endif
        }
    }

    var dashboard: DashboardResp?

    func refreshDashboard() {
        Task {
            do {
                dashboard = try await DashboardResp.get(zteSvc)
            } catch {
                print(error)
            }

            #if DEBUG
            print("Dashboard Refresh")
            #endif
        }
    }

    var networkInfo: NetworkInformation?

    func refreshNetworkInfo() {
        Task {
            networkInfo = try await NetworkInformation.get(zteSvc)
        }
    }

    var volumeInfo: VolumeInfo?

    func refreshVolumeInfo() {
        Task {
            volumeInfo = try await zteSvc.get_cmd_by_keys().0
        }
    }

    var versionInfo: VersionInfo?

    func refreshVersionInfo() {
        Task {
            versionInfo = try await VersionInfo.get(zteSvc: zteSvc)
        }
    }

    var stationInfo: StationList?

    func refreshStationInfo() {
        Task {
            stationInfo = try await StationList.get(zteSvc: zteSvc)
        }
    }

    var accessControlInfo: QueryDeviceAccessControlList?

    func refreshAccessControlInfo() {
        Task {
            accessControlInfo = try await QueryDeviceAccessControlList.get(zteSvc: zteSvc)
        }
    }

    var connectionModeInfo: ConnectionModeInfo?

    func refreshConnectionModeInfo() {
        Task {
            connectionModeInfo = try await ConnectionModeInfo.get(zteSvc: zteSvc)
        }
    }

    var cellularSettings: CellularSettings?

    func refreshCellularSettings() {
        Task {
            cellularSettings = try await CellularSettings.get(zteSvc: zteSvc)
        }
    }

    var wifiSettings: AccessPointInfoResp?

    func refreshWifiSettings() {
        Task {
            wifiSettings = try await AccessPointInfoResp.get(zteSvc: zteSvc)
        }
    }

    var smsMessages: SmsMessages?

    func refreshSmsList() {
        Task {
            smsMessages = try await SmsMessages.get(zteSvc: zteSvc)
        }
    }

    var dhcpSettings: DHCPSettings?

    func refreshDHCPSettings() {
        Task {
            dhcpSettings = try await DHCPSettings.get(zteSvc)
        }
    }

    var advantedSettings: AdvantedSettings?

    func refreshAdvantedSettings() {
        Task {
            advantedSettings = try await AdvantedSettings.get(zteSvc)
        }
    }

   
}
