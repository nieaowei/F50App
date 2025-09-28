//
//  DisconnectNetwork.swift
//  F50
//
//  Created by Nekilc on 2025/9/28.
//

import Foundation

struct SetDisconnectNetwork: Setter {
    let notCallback: Bool

    init(notCallback: Bool = true) {
        self.notCallback = notCallback
    }

    static func goformid() -> GoFormIds {
        .DISCONNECT_NETWORK
    }
}
