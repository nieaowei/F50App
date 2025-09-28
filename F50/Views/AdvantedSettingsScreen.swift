//
//  AdvantedSettingsScreen.swift
//  F50
//
//  Created by Nekilc on 2025/9/28.
//

import SwiftUI

struct AdvantedSettingsScreen: View {
    @Environment(GlobalStore.self) var g: GlobalStore

    private var info: AdvantedSettings? {
        g.advantedSettings
    }

    @State private var lteBands: [LTEBand: Bool] = [:]
    @State private var nrBands: [NRBand: Bool] = [:]

    @State private var lteBand: LTEBand = .band1
    @State private var nrBand: NRBand = .band1
    
//    @State private var
    var body: some View {
        Form {
            Section("频段锁定") {
                LabeledContent("4G") {
                    ForEach(LTEBand.allCases) { lte in
                        Toggle(lte.rawValue.description, isOn: Binding(get: {
                            lteBands[lte] ?? false
                        }, set: { val in
                            lteBands[lte] = val
                        }))
                    }
                }

                LabeledContent("5G") {
                    ForEach(NRBand.allCases) { nr in
                        Toggle(nr.rawValue.description, isOn: Binding(get: {
                            nrBands[nr] ?? false
                        }, set: { val in
                            nrBands[nr] = val
                        }))
                    }
                }
            }
            .sectionActions {
                Button("Apply") {
                    updateBand()
                }
            }

            Section("邻区信息") {
                Table(of: NeighborCellInfo.self) {
                    TableColumn("Band", value: \.band.value.description)
                    TableColumn("EARFCN", value: \.earfcn.value.description)
                    TableColumn("PCI", value: \.pci.value.description)
                    TableColumn("RSRP", value: \.rsrp.value.description)
                    TableColumn("RSRQ", value: \.rsrq.value.description)
                    TableColumn("SINR", value: \.sinr.value.description)
                } rows: {
                    ForEach(info?.neighbor_cell_info ?? []) { cell in
                        TableRow(cell)
                    }
                }
            }

            Section {
                Table(of: LockedCellInfo.self) {
                    TableColumn("Rate", value: \.rat.value.description)
                    TableColumn("EARFCN", value: \.earfcn.value.description)
                    TableColumn("PCI", value: \.pci.value.description)
                } rows: {
                    ForEach(info?.locked_cell_info ?? []) { cell in
                        TableRow(cell)
                    }
                }
            } header: {
                HStack{
                    Text("已锁定小区信息")
                    Spacer()
                    Button("新增") {
                        
                    }
                }
            }
        }
        .formStyle(.grouped)
        .task {
            g.refreshAdvantedSettings()
        }
        .task(id: g.advantedSettings) {
            if let settings = g.advantedSettings {
                for lte in settings.lockedLTE {
                    lteBands[lte] = true
                }
                for nr in settings.lockedNR {
                    nrBands[nr] = true
                }
            }
        }
    }

    func updateBand() {
        Task {
            var set = SetNRBandLock()
            for (band, enable) in nrBands {
                if enable {
                    set.appendBand(band)
                }
            }
            _ = try await set.set(g.zteSvc)
        }
    }
}

#Preview {
    AdvantedSettingsScreen()
}
