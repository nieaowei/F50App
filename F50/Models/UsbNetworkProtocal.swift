//
//  UsbNetworkProtocal.swift
//  F50
//
//  Created by Nekilc on 2025/9/27.
//

import Foundation
import SwiftUI

enum USBNetworkProtocal: String {
    case Auto = "0"
    case RNDIS = "1"
    case CDC_ECM = "2"

    var localizedString: LocalizedStringKey {
        switch self {
        case .Auto:
            LocalizedStringKey("Auto")

        case .RNDIS:
            LocalizedStringKey("RNDIS")

        case .CDC_ECM:
            LocalizedStringKey("CDC_ECM")
        }
    }
}

// struct USBNetworkProtocal{
//
// }
