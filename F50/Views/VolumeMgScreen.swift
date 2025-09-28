//
//  VolumeMgScreen.swift
//  F50
//
//  Created by Nekilc on 2025/9/24.
//

import SwiftUI

struct VolumeMgScreen: View {
    @Environment(GlobalStore.self) private var g: GlobalStore

    private var info: VolumeInfo? {
        g.volumeInfo
    }

    @State private var volumeSwitch: Bool = false
    @State private var clearSwitch: Bool = false
    @State private var clearDate: UInt64 = 1
    @State private var limitUnit: VolumeLimitUnit = .Data
    @State private var usedVolume: Float = 0
    @State private var totalVolume: UInt64 = 0
    @State private var unit: VolumeLimitUnit = .Data

//    @State private var setter: SetDataLimitSetting = .init()

    var body: some View {
        Form {
            Section {
                Toggle("Data Management", isOn: $volumeSwitch)
                if volumeSwitch {
                    Toggle("Traffic Clear", isOn: $clearSwitch)
                    if clearSwitch {
                        TextField("Clear Date", value: $clearDate, format: .number)
                    }
                    Picker("Data Type", selection: $unit) {
//                        ForEach(VolumeLimitUnit.allCases) { un in
//                            Text(un.localizedString).tag(un)
//                        }
                    }
                    if info != nil {
                        LabeledContent("Used") {
                            TextField("", value: $usedVolume, format: .number)
                            Text(verbatim: unit == .Data ? "GB" : "Hour")
                        }
                        LabeledContent("Plan") {
                            TextField("", value: $totalVolume, format: .number)
                            Text(verbatim: unit == .Data ? "GB" : "Hour")
                        }
                    }
                }
            }
            .sectionActions {
                Button("Apply") {
                    update()
                }
            }
        }
        .formStyle(.grouped)
        .task {
            g.refreshVolumeInfo()
        }
//        .onChange(of: info) { _, new in
//            volumeSwitch = new.data_volume_limit_switch.value
//            clearSwitch = new.wan_auto_clear_flow_data_switch.rawValue
//            clearDate = new.traffic_clear_date.value
//            usedVolume =  new.data_volume_limit_unit == .Data ? (Float(new.used_volume) / 1024 / 1024 / 1024 ) : (Float(new.used_volume) / 60)
//            totalVolume = new.data_volume_limit_unit == .Data ? new.data_volume_limit_size_num / 1024 : new.data_volume_limit_size_num / 60
//            unit = new.data_volume_limit_unit
//        }
        .task(id: g.volumeInfo) {
            if let info {
                volumeSwitch = info.data_volume_limit_switch.value
                clearSwitch = info.wan_auto_clear_flow_data_switch.rawValue
                clearDate = info.traffic_clear_date.value
                usedVolume = info.data_volume_limit_unit == .Data ? (Float(info.used_volume) / 1024 / 1024 / 1024) : (Float(info.used_volume) / 60)
                totalVolume = info.data_volume_limit_unit == .Data ? info.data_volume_limit_size_num / 1024 : info.data_volume_limit_size_num / 60
                unit = info.data_volume_limit_unit
            }
        }
    }

    func update() {
        Task {
            do {
                let p = SetDataLimitSetting(data_volume_limit_switch: volumeSwitch, data_volume_limit_unit: unit, data_volume_limit_size: totalVolume, wan_auto_clear_flow_data_switch: clearSwitch, traffic_clear_date: clearDate, notify_deviceui_enable: true, data_volume_alert_percent: 90)
                let res = try await p.set(g.zteSvc)
                if res.result.rawValue {}

                let p1 = SetFlowCalibrationManual(calibration_way: unit, time: UInt64(usedVolume * 60 * 60), data: UInt64(usedVolume * 1024 * 1024 * 1024))
                let res1 = try await p1.set(g.zteSvc)

            } catch {
                print(error)
            }
        }
    }
}
