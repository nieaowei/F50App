//
//  Contans.swift
//  F50
//
//  Created by Nekilc on 2025/9/22.
//

import Foundation
import SwiftUI

enum VolumeLimitUnit: String, Codable, CaseIterable,Identifiable {
    var id: String{
        self.rawValue
    }
    case Data = "data"
    case Time = "time"
    
    var localizedString: LocalizedStringKey{
        switch self {
        case .Data:
            LocalizedStringKey("Data")
        case .Time:
            LocalizedStringKey("Time")
        }
    }
}

nonisolated struct DefaultResp: Decodable, Sendable {
    let result: StringBool
}

nonisolated protocol Setter: Encodable & Sendable {
    associatedtype Resp: Decodable & Sendable = DefaultResp

    func set(_ zteSvc: ZTEService) async throws -> Resp
    func getAD(_ zteSvc: ZTEService) async throws -> String

    static func goformid() -> GoFormIds
}

extension Setter {
    func set(_ zteSvc: ZTEService) async throws -> Resp {
        let ad = try await self.getAD(zteSvc)
        return try await zteSvc.set_cmd(goformId: Self.goformid(), params: self, extras: ["AD": ad]).0
    }

    func getAD(_ zteSvc: ZTEService) async throws -> String {
        try await F50.getAD(zteSvc: zteSvc)
    }
}

enum Cmds: String, Codable {
    case LD
    case RD
    case dial_mode
    case privacy_read_flag
    case RadioOff
    case station_mac
    case signalbar
    case rssi
    case imsi
    case hardware_version
    case ipv6_wan_ipaddr
    case web_version
    case iccid
    case ipv6_pdp_type
    case wa_inner_version
    case wan_ipaddr
    case Z5g_rsrp // 信号
    case imei
    case sim_imsi
    case pdp_type
    case network_type
    case network_provider
    case realtime_time
    // 流量管理
    case data_volume_limit_switch // 流量管理开关 0 1 int
    case monthly_tx_bytes // int
    case monthly_rx_bytes // int
    case data_volume_limit_unit // 流量管理类型 time data
    case data_volume_limit_size //
    case data_volume_alert_percent // 告警百分比
    case monthly_time // 这个月已使用时间 int
    case wan_auto_clear_flow_data_switch // 流量清零开关 on off
    case traffic_clear_date // 清零日期
    //
    case realtime_tx_thrpt
    case realtime_rx_thrpt
    //
    case upg_roam_switch
    case roam_setting_option
    // sms
    case sms_capacity_info
    case sms_data_total
    case sms_cmd
    case sms_cmd_status_result
    case sms_unread_num
    case sms_dev_unread_num
    case sms_sim_unread_num
    case sms_received_flag
    //
    case cr_version

    case pin_status
    case loginfo
    case opms_wan_mode
    case opms_wan_auto_mode
    case new_version_state
    case current_upgrade_state

    case usb_network_protocal
    case indicator_light_switch
    case usb_port_switch
    case samba_switch
    // wifi
    case wifi_onoff_state
    case wifi_chip1_ssid1_ssid
    case queryWiFiModuleSwitch // WiFiModuleSwitch
    case queryAccessPointInfo

    case network_information
    case Lte_ca_status
    case performance_mode

    // Station
    case lan_station_list
    case station_list
    case queryDeviceAccessControlList
    case wifi_access_sta_num // wifi user number

    /**
     {
         "connectionMode": "auto_dial",
         "autoConnectWhenRoaming": "off"
     }
     */
    case ConnectionMode
    case net_select
    case net_select_mode
    case modem_main_state
    case ppp_status
    // muanal
    case m_netselect_save
    case m_netselect_contents
    // dhcp
    case lan_ipaddr
    case lan_netmask
    case mac_address
    case dhcpEnabled
    case dhcpStart
    case dhcpEnd
    case dhcpLease_hour
    case mtu
    case tcp_mss
    // debug
    case lte_band_lock
    case nr_band_lock
    case neighbor_cell_info
    case locked_cell_info // {"earfcn": "633984","pci": "488","rat": "16"}
}

enum GoFormIds: String, Codable {
    
    case LOGIN
    case INDICATOR_LIGHT_SETTING // indicator_light_switch
    case USB_PORT_SETTING // usb_port_switch
    case SAMBA_SETTING // samba_switch
    case setAccessPointInfo // ChipIndex AccessPointIndex QrImageShow lan_sec_ssid_control wifi_syncparas_flag AccessPointSwitchStatus SSID ApIsolate AuthMode ApBroadcastDisabled
    case setWiFiChipAdvancedInfo24G_5G
    case PERFORMANCE_MODE_SETTING //  performance_mode  1 0
    /**
     DATA_LIMIT_SETTING
         data_volume_limit_unit: data
         data_volume_limit_size: 100_1024
         data_volume_alert_percent: 90
         wan_auto_clear_flow_data_switch: on
         traffic_clear_date: 18
         data_volume_limit_switch: 1
         notify_deviceui_enable: 0
         AD: B55C25AAC035696A77E3EC7861BA449E645A7D51133811AEE854F0C562187341
     */
    case DATA_LIMIT_SETTING //
    /**
     calibration_way: data
     time: 0
     data: 53397180908
     AD: B55C25AAC035696A77E3EC7861BA449E645A7D51133811AEE854F0C562187341
     */
    case FLOW_CALIBRATION_MANUAL
    /**
     mac: 2e:2c:d4:dd:d2:ce
     hostname: Macbook
     */
    case EDIT_HOSTNAME
    /**
     AclMode: 2
     WhiteMacList
     BlackMacList: 2e:2c:d4:dd:d2:c1;
     WhiteNameList
     BlackNameList: test;
     */
    case setDeviceAccessControlList
    /**
     ConnectionMode: auto_dial
     roam_setting_option: off
     */
    case SET_CONNECTION_MODE
    /**
     BearerPreference: WL_AND_5G
     */
    case SET_BEARER_PREFERENCE
    /*
     SwitchOption: 0
     */
    case switchWiFiModule
    /**
     ChipEnum
     chip2
     GuestEnable
     0
     */
    case switchWiFiChip
    /*
     lanIp, lanNetmask, lanDhcpType(DISABLE,SERVER), dhcpStart, dhcpEnd, dhcpLease, dhcp_reboot_flag(Int 1 0), mac_ip_reset
     */
    case DHCP_SETTING
    /**
     usb_network_protocal  0- auto 1  RNDIS  2 CDC-ECM
     */
    case SET_USB_NETWORK_PROTOCAL
    /*
     pci: 488
     earfcn: 633984
     rat: 16
     */
    case CELL_LOCK
    case UNLOCK_ALL_CELL
    // reboot 设备
    case REBOOT_DEVICE
//    case SHUTDOWN_DEVICE invalid
    // lte_band_lock: 41
    case LTE_BAND_LOCK
    // nr_band_lock: 41,78
    case NR_BAND_LOCK
    // notCallback
    case DISCONNECT_NETWORK
    case CONNECT_NETWORK
    
}
