//
//  VersionInfo.swift
//  F50
//
//  Created by Nekilc on 2025/9/24.
//

import Foundation

struct VersionInfo: AutoCmds {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case wa_inner_version
        case cr_version
    }

    let wa_inner_version: String
    let cr_version: String

    mutating func get(zteSvc: ZTEService) async throws {
        self = try await zteSvc.get_cmd_by_keys().0
    }

    static func get(zteSvc: ZTEService) async throws -> VersionInfo {
        try await zteSvc.get_cmd_by_keys().0
    }
}
