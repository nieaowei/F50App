//
//  IPAddr.swift
//  F50
//
//  Created by Nekilc on 2025/9/27.
//
import Foundation
import Network
import Darwin // macOS/iOS 的 inet_pton

/// Rust 风格的 IP 地址类型
nonisolated enum IPAddress: Codable, Hashable {
    case v4(String)
    case v6(String)

    // MARK: - 初始化
    init(_ string: String) throws {
        if IPAddress.isValidIPv4(string) {
            self = .v4(string)
        } else if IPAddress.isValidIPv6(string) {
            self = .v6(string)
        } else {
            throw NSError(domain: "IPAddress",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid IP address: \(string)"])
        }
    }

    // MARK: - 字符串表示
    var stringValue: String {
        switch self {
        case .v4(let s), .v6(let s):
            return s
        }
    }

    // MARK: - 转 Network Host
    var nwHost: NWEndpoint.Host {
        NWEndpoint.Host(stringValue)
    }

    // MARK: - Codable
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        try self.init(str)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }

    // MARK: - 校验方法
    private static func isValidIPv4(_ ip: String) -> Bool {
        var addr = in_addr()
        return ip.withCString { inet_pton(AF_INET, $0, &addr) } == 1
    }

    private static func isValidIPv6(_ ip: String) -> Bool {
        var addr6 = in6_addr()
        return ip.withCString { inet_pton(AF_INET6, $0, &addr6) } == 1
    }
}
