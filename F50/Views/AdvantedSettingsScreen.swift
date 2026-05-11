//
//  AdvantedSettingsScreen.swift
//  F50
//
//  Created by Nekilc on 2025/9/28.
//

import SwiftUI
import OSLog

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
                    Button("Unlock All") {
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
        Logger.ui.debug("Updating band lock settings")
        Task {
            var lteSet = SetLTEBandLock()
            for (band, enable) in lteBands {
                if enable {
                    lteSet.appendBand(band)
                }
            }
            _ = await lteSet.set(g.zteSvc)
            Logger.ui.info("LTE band lock applied")

            var nrSet = SetNRBandLock()
            for (band, enable) in nrBands {
                if enable {
                    nrSet.appendBand(band)
                }
            }
            _ = await nrSet.set(g.zteSvc)
            Logger.ui.info("NR band lock applied")

            g.refreshAdvantedSettings()
        }
    }

    func updateLockInfo() {
        _ = SetCellLock(earfcn: .init(EARFCN), pci: .init(pci), rat: rat)
        Logger.ui.debug("updateLockInfo called but not executed (unimplemented)")
    }

    func updateLockInfoFromNeighbor(_ neighbor: NeighborCellInfo) {
        Logger.ui.debug("Locking cell from neighbor: EARFCN=\(neighbor.earfcn.value) PCI=\(neighbor.pci.value)")
        guard let toolbar = g.toolbar else {
            Logger.ui.error("Cannot lock cell: toolbar info not loaded")
            return
        }
        var rat = RatType.Rat4G
        if toolbar.network_type.is4G {
            rat = RatType.Rat4G
        } else if toolbar.network_type.is5G {
            rat = RatType.Rat5G
        } else {
            Logger.ui.error("Cannot lock cell: unknown network type")
            return
        }
        Task {
            let res = await SetCellLock(earfcn: neighbor.earfcn, pci: neighbor.pci, rat: rat).set(g.zteSvc)
            if case .success = res {
                Logger.ui.info("Cell locked successfully")
            } else if case .failure(let err) = res {
                Logger.ui.error("Failed to lock cell: \(err.localizedDescription)")
            }
            g.refreshAdvantedSettings()
        }
    }

    func unlockAll() {
        Logger.ui.debug("Unlocking all cells")
        Task {
            let res = await UnlockAllCell().set(g.zteSvc)
            if case .success = res {
                Logger.ui.info("All cells unlocked")
            } else if case .failure(let err) = res {
                Logger.ui.error("Failed to unlock all cells: \(err.localizedDescription)")
            }
            g.refreshAdvantedSettings()
        }
    }
}

#Preview {
    AdvantedSettingsScreen()
}
