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



extension Int128 {
    var displayByteCount: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB] // 限制单位
        formatter.countStyle = .binary // .decimal 也可以
        formatter.includesUnit = true
        formatter.includesCount = true
        formatter.formattingContext = .dynamic
        formatter.allowsNonnumericFormatting = false
        formatter.isAdaptive = true
        return formatter.string(for: Int128(self))!
    }
}

nonisolated extension UInt64 {
    var displayByteCount: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB] // 限制单位
        formatter.countStyle = .binary // .decimal 也可以
        formatter.includesUnit = true
        formatter.includesCount = true
        formatter.formattingContext = .dynamic
        formatter.allowsNonnumericFormatting = false
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: Int64(self))
    }

    var displayTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second] // 支持的单位
        formatter.unitsStyle = .abbreviated // 输出样式：h, m, s
        formatter.zeroFormattingBehavior = .dropAll // 不显示 0 值的单位
        return formatter.string(from: TimeInterval(self)) ?? "0s"
    }
}
