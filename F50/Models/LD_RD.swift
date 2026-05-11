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

    static func get(zteSvc: ZTEService) async -> Result<LD, Error> {
        await zteSvc.get_cmd(cmds: [.LD]).map(\.0)
    }
}

struct RD: Decodable {
    let RD: String
    static func get(zteSvc: ZTEService) async -> Result<RD, Error> {
        await zteSvc.get_cmd(cmds: [.RD]).map(\.0)
    }
}


func defaultGetAD(zteSvc: ZTEService) async -> Result<String, Error> {
    let rdResult: Result<RD, Error> = await RD.get(zteSvc: zteSvc)
    guard case .success(let rd) = rdResult else {
        if case .failure(let err) = rdResult {
            return .failure(err)
        }
        fatalError()
    }
    let vResult: Result<VersionInfo, Error> = await VersionInfo.get(zteSvc: zteSvc)
    guard case .success(let v) = vResult else {
        if case .failure(let err) = vResult {
            return .failure(err)
        }
        fatalError()
    }

    let s1 = (v.wa_inner_version+v.cr_version).sha256().uppercased()
    let s2 = (s1 + rd.RD).sha256().uppercased()

    return .success(s2)
}

extension String {
    func sha256() -> String {
        let inputData = Data(self.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}