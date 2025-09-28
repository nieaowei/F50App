import Foundation

/// 类型化 MAC 地址
nonisolated struct MACAddress: Codable, Hashable {
    /// 6 个字节
    let bytes: [UInt8]

    /// 初始化：字符串格式 "00:1A:2B:3C:4D:5E"
    init(_ string: String) throws {
        let parts = string.split(separator: ":")
        guard parts.count == 6 else {
            throw NSError(domain: "MACAddress",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "MAC must have 6 parts"])
        }
        self.bytes = try parts.map { part in
            guard let b = UInt8(part, radix: 16) else {
                throw NSError(domain: "MACAddress",
                              code: 2,
                              userInfo: [NSLocalizedDescriptionKey: "Invalid byte: \(part)"])
            }
            return b
        }
    }

    /// 初始化：直接传字节数组
    init(_ bytes: [UInt8]) throws {
        guard bytes.count == 6 else {
            throw NSError(domain: "MACAddress",
                          code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "MAC must have 6 bytes"])
        }
        self.bytes = bytes
    }

    /// 返回标准字符串表示 "00:1A:2B:3C:4D:5E"
    var stringValue: String {
        bytes.map { String(format: "%02X", $0) }.joined(separator: ":")
    }

    /// 自定义 Debug 输出
    var debugDescription: String {
        stringValue
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
}
