//
//  Global.swift
//  F50
//
//  Created by Nekilc on 2025/9/22.
//

import CryptoKit
import Observation
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "app.F50", category: "GlobalStore")

struct LDResp: AutoCmds {
    let LD: String
    enum CodingKeys: String, CodingKey, CaseIterable {
        case LD
    }
}

struct LoginParams: Encodable {
    private let password: String

    init?(password: String, ld: String) {
        guard let passwordData = password.data(using: .utf8) else { return nil }
        let ph = SHA256.hash(data: passwordData)
        let phHex = ph.map { String(format: "%02x", $0) }.joined().uppercased()
        let catString = phHex + ld
        guard let catData = catString.data(using: .utf8) else { return nil }
        let catH = SHA256.hash(data: catData)
        let catHex = catH.map { String(format: "%02x", $0) }.joined().uppercased()
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

enum LoginError: Error {
    case invalidPassword
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
        case msisdn
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
    let msisdn: String?
    let imei: String
    let Z5g_rsrp: Int
    let wifi_access_sta_num: StringUInt64

    let monthly_tx_bytes: UInt64
    let monthly_rx_bytes: UInt64
    let data_volume_limit_unit: VolumeLimitUnit
    let data_volume_limit_size: String
    let monthly_time: UInt64

    let wan_auto_clear_flow_data_switch: StringBool
    let traffic_clear_date: StringUInt64

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

    func login(password: String) async -> Result<LoginResp, Error> {
        let ldResult = await LD.get(zteSvc: zteSvc)
        guard case .success(let ld) = ldResult else {
            if case .failure(let err) = ldResult { return .failure(err) }
            fatalError()
        }
        guard let params = LoginParams(password: password, ld: ld.LD) else {
            return .failure(LoginError.invalidPassword)
        }
        return await zteSvc.set_cmd(goformId: .LOGIN, params: params).map(\.0)
    }

    func refreshLogin(password: String) {
        Task {
            let result = await self.login(password: password)
            if case .failure(let err) = result {
                logger.error("Login failed: \(err.localizedDescription)")
            }
        }
    }

    func toolbar() async -> Result<ToolbarResp, Error> {
        await zteSvc.get_cmd_by_keys().map(\.0)
    }

    var toolbar: ToolbarResp?

    func refreshToolbar() {
        Task {
            let toolbarResult: Result<ToolbarResp, Error> = await self.toolbar()
            if case .success(let data) = toolbarResult {
                toolbar = data
            } else if case .failure(let err) = toolbarResult {
                logger.error("Failed to refresh toolbar: \(err.localizedDescription)")
            }
        }
    }

    var dashboard: DashboardResp?

    func refreshDashboard() {
        Task {
            if case .success(let data) = await DashboardResp.get(zteSvc) {
                dashboard = data
            } else {
                logger.error("Failed to refresh dashboard")
            }
        }
    }

    var networkInfo: NetworkInformation?

    func refreshNetworkInfo() {
        Task {
            if case .success(let data) = await NetworkInformation.get(zteSvc) {
                networkInfo = data
            } else {
                logger.error("Failed to refresh network info")
            }
        }
    }

    var volumeInfo: VolumeInfo?

    func refreshVolumeInfo() {
        Task {
            let result: Result<(VolumeInfo, URLResponse), Error> = await zteSvc.get_cmd_by_keys()
            if case .success(let (data, _)) = result {
                volumeInfo = data
            } else {
                logger.error("Failed to refresh volume info")
            }
        }
    }

    var versionInfo: VersionInfo?

    func refreshVersionInfo() {
        Task {
            let result: Result<VersionInfo, Error> = await VersionInfo.get(zteSvc: zteSvc)
            if case .success(let data) = result {
                versionInfo = data
            }
        }
    }

    var stationInfo: StationList?

    func refreshStationInfo() {
        Task {
            let result: Result<StationList, Error> = await StationList.get(zteSvc: zteSvc)
            if case .success(let data) = result {
                stationInfo = data
            } else {
                logger.error("Failed to refresh station info")
            }
        }
    }

    var accessControlInfo: QueryDeviceAccessControlList?

    func refreshAccessControlInfo() {
        Task {
            let result: Result<QueryDeviceAccessControlList, Error> = await QueryDeviceAccessControlList.get(zteSvc: zteSvc)
            if case .success(let data) = result {
                accessControlInfo = data
            } else {
                logger.error("Failed to refresh access control info")
            }
        }
    }

    var connectionModeInfo: ConnectionModeInfo?

    func refreshConnectionModeInfo() {
        Task {
            let result: Result<ConnectionModeInfo, Error> = await ConnectionModeInfo.get(zteSvc: zteSvc)
            if case .success(let data) = result {
                connectionModeInfo = data
            } else {
                logger.error("Failed to refresh connection mode info")
            }
        }
    }

    var cellularSettings: CellularSettings?

    func refreshCellularSettings() {
        Task {
            let result: Result<CellularSettings, Error> = await CellularSettings.get(zteSvc: zteSvc)
            if case .success(let data) = result {
                cellularSettings = data
            } else {
                logger.error("Failed to refresh cellular settings")
            }
        }
    }

    var wifiSettings: AccessPointInfoResp?

    func refreshWifiSettings() {
        Task {
            let result: Result<AccessPointInfoResp, Error> = await AccessPointInfoResp.get(zteSvc: zteSvc)
            if case .success(let data) = result {
                wifiSettings = data
            } else {
                logger.error("Failed to refresh WiFi settings")
            }
        }
    }

    var smsMessages: SmsMessages?

    func refreshSmsList() {
        Task {
            let result: Result<SmsMessages, Error> = await SmsMessages.get(zteSvc: zteSvc)
            if case .success(let data) = result {
                smsMessages = data
            } else {
                logger.error("Failed to refresh SMS list")
            }
        }
    }

    var dhcpSettings: DHCPSettings?

    func refreshDHCPSettings() {
        Task {
            let result: Result<DHCPSettings, Error> = await DHCPSettings.get(zteSvc)
            if case .success(let data) = result {
                dhcpSettings = data
            } else {
                logger.error("Failed to refresh DHCP settings")
            }
        }
    }

    var deviceSettings: DeviceSettings?

    func refreshDeviceSettings() {
        Task {
            let result: Result<DeviceSettings, Error> = await DeviceSettings.get(zteSvc)
            if case .success(let data) = result {
                deviceSettings = data
            } else {
                logger.error("Failed to refresh device settings")
            }
        }
    }

    var advantedSettings: AdvantedSettings?

    func refreshAdvantedSettings() {
        Task {
            let result: Result<AdvantedSettings, Error> = await AdvantedSettings.get(zteSvc)
            if case .success(let data) = result {
                advantedSettings = data
            } else {
                logger.error("Failed to refresh advanced settings")
            }
        }
    }
}
