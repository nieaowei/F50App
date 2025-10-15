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

    @State private var showLock: Bool = false

    @State private var EARFCN: UInt64 = 0
    @State private var pci: UInt64 = 0
    @State private var rat: RatType = .Rat4G
//    @State private var
    var body: some View {
        Form {
            Section("Band Selection") {
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

            Section("Neighbor Cell Information") {
                Table(of: NeighborCellInfo.self) {
                    TableColumn("Band", value: \.band.value.description).width(30)
                    TableColumn("EARFCN", value: \.earfcn.value.description)
                    TableColumn("PCI", value: \.pci.value.description)
                    TableColumn("RSRP", value: \.rsrp.value.description)
                    TableColumn("RSRQ", value: \.rsrq.value.description)
                    TableColumn("SINR", value: \.sinr.value.description)
                    TableColumn("Operation") { cell in
                        Button("Lock") {
                            updateLockInfoFromNeighbor(cell)
                        }
                        .foregroundStyle(.tint)
                    }
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
                HStack {
                    Text("Locked Cell Information")
                    Spacer()
                    Button("New") {
                        showLock = true
                    }
                    Button("Unlock All"){
                        unlockAll()
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
        .sheet(isPresented: $showLock) {
            Form {
                Section {
                    Picker("Network Type", selection: $rat) {
                        ForEach(RatType.allCases) { rt in
                            Text(rt.localizedString).tag(rt)
                        }
                    }
                    TextField("EARFCN", value: $EARFCN, format: .number)
                    TextField("PCI", value: $pci, format: .number)
                }
                .sectionActions {
                    HStack {
                        Button("Cancel") {
                            showLock = false
                        }
                        Button("OK") {}
                    }
                }
            }
            .formStyle(.grouped)
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
            
            g.refreshAdvantedSettings()
        }
    }

    func updateLockInfo() {
        _ = SetCellLock(earfcn: .init(EARFCN), pci: .init(pci), rat: rat)
    }

    func updateLockInfoFromNeighbor(_ neighbor: NeighborCellInfo) {
        guard let toolbar = g.toolbar else {
            return
        }
        var rat = RatType.Rat4G
        if toolbar.network_type.is4G {
            rat = RatType.Rat4G
        } else if toolbar.network_type.is5G {
            rat = RatType.Rat5G
        } else {
            return
        }
        Task {
            let res = try await SetCellLock(earfcn: neighbor.earfcn, pci: neighbor.pci, rat: rat).set(g.zteSvc)
            print(res)
            g.refreshAdvantedSettings()
        }
    }
    
    func unlockAll(){
        Task{
            let res = try await UnlockAllCell().set(g.zteSvc)
            print(res)
            g.refreshAdvantedSettings()
        }
    }
}

#Preview {
    AdvantedSettingsScreen()
}
