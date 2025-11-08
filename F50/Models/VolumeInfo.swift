//
//  VolumeInfo.swift
//  F50
//
//  Created by Nekilc on 2025/9/24.
//

import Foundation

struct VolumeInfo: AutoCmds, Equatable {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case data_volume_limit_switch
        case monthly_tx_bytes
        case monthly_rx_bytes
        case data_volume_limit_unit
        case data_volume_limit_size
        case data_volume_alert_percent
        case monthly_time
        case wan_auto_clear_flow_data_switch
        case traffic_clear_date
//        case notify_deviceui_enable
    }

    let data_volume_limit_switch: UInt8Bool // 流量管理开关 0 1 int
    let data_volume_limit_unit: VolumeLimitUnit // 流量管理类型 time data
    let data_volume_limit_size: String //
//    let notify_deviceui_enable: UInt8Bool
    let data_volume_alert_percent: StringUInt64 // 告警百分比
    let wan_auto_clear_flow_data_switch: StringBool // 流量清零开关 on off
    let traffic_clear_date: StringUInt64 // 清零日期

    let monthly_time: UInt64 // 这个月已使用时间 int
    let monthly_tx_bytes: UInt64 // int
    let monthly_rx_bytes: UInt64 // int

    // MB  Min
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

    // byte min
    var total_volume: UInt64 {
        switch data_volume_limit_unit {
        case .Data:
            return data_volume_limit_size_num * 1024 * 1024
        case .Time:
            return data_volume_limit_size_num
        }
    }

    // byte min
    var used_volume: UInt64 {
        switch data_volume_limit_unit {
        case .Data:
            return monthly_rx_bytes + monthly_tx_bytes
        case .Time:
            return monthly_time / 60
        }
    }

    // mb min
    var used_volume_mb: Float {
        switch data_volume_limit_unit {
        case .Data:
            return Float(UInt32((monthly_rx_bytes + monthly_tx_bytes) / 1024 / 1024))
        case .Time:
            return Float(UInt64(monthly_time / 60))
        }
    }

    var remain_volume: UInt64 {
        total_volume - used_volume
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

struct SetDataLimitSetting: Setter {
    static func goformid() -> GoFormIds {
        .DATA_LIMIT_SETTING
    }

    private var data_volume_limit_switch: UInt8Bool // 流量管理开关 0 1 int
    private var data_volume_limit_unit: VolumeLimitUnit // 流量管理类型 time data
    private var data_volume_limit_size: String //
    private var wan_auto_clear_flow_data_switch: StringBool // 流量清零开关 on off
    private var traffic_clear_date: UInt64 // 清零日期
    private var notify_deviceui_enable: UInt8Bool = true
    private var data_volume_alert_percent: UInt64 // 告警百分比

    init(data_volume_limit_switch: Bool, data_volume_limit_unit: VolumeLimitUnit, data_volume_limit_size: UInt64, wan_auto_clear_flow_data_switch: Bool, traffic_clear_date: UInt64, notify_deviceui_enable: Bool, data_volume_alert_percent: UInt64) {
        self.data_volume_limit_switch = data_volume_limit_switch.u8
        self.data_volume_limit_unit = data_volume_limit_unit
        switch data_volume_limit_unit {
        case .Data:
            self.data_volume_limit_size = "\(data_volume_limit_size)_1024"

        case .Time:
            self.data_volume_limit_size = data_volume_limit_size.description
        }

        self.wan_auto_clear_flow_data_switch = wan_auto_clear_flow_data_switch ? .OnTrue : .OffFalse
        self.traffic_clear_date = traffic_clear_date
        self.notify_deviceui_enable = notify_deviceui_enable.u8
        self.data_volume_alert_percent = data_volume_alert_percent
    }
}

struct SetFlowCalibrationManual: Setter {
    static func goformid() -> GoFormIds {
        .FLOW_CALIBRATION_MANUAL
    }

    private let calibration_way: VolumeLimitUnit
    private let time: UInt64 // min
    private let data: UInt64 // byte

    init(calibration_way: VolumeLimitUnit, time: UInt64, data: UInt64) {
        self.calibration_way = calibration_way
        self.time = time
        self.data = data
    }
}
