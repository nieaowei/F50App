//
//  UInt64.swift
//  F50
//
//  Created by Nekilc on 2025/9/25.
//

import Foundation

extension UInt64 {
    func mb2gb() -> UInt64 {
        self / 1024
    }

    func byte2gb() -> UInt64 {
        self / 1024 / 1024 / 1024
    }

    func second2min() -> UInt64 {
        self / 60
    }

    func second2hour() -> UInt64 {
        self / 60 / 60
    }

    func min2hour() -> UInt64 {
        self / 60
    }
}
