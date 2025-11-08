//
//  LD_RD.swift
//  F50
//
//  Created by Nekilc on 2025/9/24.
//
import CryptoKit
import Foundation

struct LD: Decodable {
    let LD: String

    static func get(zteSvc: ZTEService) async throws -> LD {
        try await zteSvc.get_cmd(cmds: [.LD]).0
    }
}

struct RD: Decodable {
    let RD: String
    static func get(zteSvc: ZTEService) async throws -> RD {
        try await zteSvc.get_cmd(cmds: [.RD]).0
    }
}


func defaultGetAD(zteSvc: ZTEService)async throws -> String{
    let rd = try await RD.get(zteSvc: zteSvc).RD
    let v = try await VersionInfo.get(zteSvc: zteSvc)
    
    let s1 = (v.wa_inner_version+v.cr_version).sha256().uppercased()
    let s2 = (s1 + rd).sha256().uppercased()
    
    return s2
}

extension String {
    func sha256() -> String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
