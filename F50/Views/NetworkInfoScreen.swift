//
//  NetworkInfoScreen.swift
//  F50
//
//  Created by Nekilc on 2025/9/21.
//

import SwiftUI

struct NetworkInfoScreen: View {
    @Environment(GlobalStore.self) var g

    var info: NetworkInformation? {
        g.networkInfo
    }

    var body: some View {
        Form {
            LabeledContent("3G/4G Frequency", value: info?.Lte_fcn?.description ?? "--")
            LabeledContent("3G/4G Connected Band", value: info?.Lte_bands?.rawValue.description ?? "--")
            LabeledContent("3G/4G Signal Strength", value: info?.Lte_signal_strength?.description ?? "--")
            LabeledContent("3G/4G ECIO/SINR", value: info?.Lte_snr?.description ?? "--")
            LabeledContent("3G/4G PCI", value: info?.Lte_pci?.description ?? "--")
            LabeledContent("3G/4G Cell ID", value: info?.Lte_cell_id?.description ?? "--")
            LabeledContent("4G CA Status", value: info?.Lte_ca_status.rawValue ?? "--")
            LabeledContent("5G Frequency", value: info?.Nr_fcn?.description ?? "--")
            LabeledContent("5G Connected Band", value: info?.Nr_bands?.rawValue.description ?? "--")
            LabeledContent("5G Signal Strength", value: info?.Nr_signal_strength?.description ?? "--")
            LabeledContent("5G SINR", value: info?.Nr_snr?.description ?? "--")
            LabeledContent("5G PCI", value: info?.Nr_pci?.description ?? "--")
            LabeledContent("5G Cell ID", value: info?.Nr_cell_id?.description ?? "--")
        }
        .formStyle(.grouped)
        .task{
            g.refreshNetworkInfo()
        }
    }
}

#Preview {
    NetworkInfoScreen()
}
