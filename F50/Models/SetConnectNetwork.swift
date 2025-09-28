//
//  SetConnectNetwork.swift
//  F50
//
//  Created by Nekilc on 2025/9/28.
//

import Foundation

struct SetConnectNetwork: Setter{
    let notCallback: Bool
    
    init(notCallback: Bool = true) {
        self.notCallback = notCallback
    }
    
    static func goformid() -> GoFormIds {
        .CONNECT_NETWORK
    }
}
