//
//  Bool.swift
//  F50
//
//  Created by Nekilc on 2025/9/24.
//

import Foundation

nonisolated enum StringBool: String, Codable, RawRepresentable {
    case IntTrue = "1"
    case IntFalse = "0"

    case OnTrue = "on"
    case OffFalse = "off"

    case SuccessTrue = "success"

    var rawValue: Bool {
        switch self {
        case .IntTrue, .OnTrue, .SuccessTrue:
            true
        case .IntFalse, .OffFalse:
            false
        }
    }
}

nonisolated enum IntBool: UInt8, Codable, RawRepresentable {
    case True = 1
    case False = 0

    var rawValue: Bool {
        switch self {
        case .True:
            true
        case .False:
            false
        }
    }
}

nonisolated struct UInt8Bool: Codable, Equatable {
    let value: Bool

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(UInt8.self)
        self.value = str == 1 ? true : false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value ? 1 : 0)
    }
}

extension Bool {
    nonisolated var u8: UInt8Bool {
        UInt8Bool(booleanLiteral: self)
    }
}

nonisolated extension UInt8Bool: ExpressibleByBooleanLiteral {
    init(booleanLiteral value: Bool) {
        self.value = value
    }

    typealias BooleanLiteralType = Bool
}

nonisolated struct StringUInt64: Codable, Equatable {
    let value: UInt64

    init(_ value: UInt64) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        self.value = UInt64(str) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(value))
    }
}

nonisolated extension StringUInt64: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.value = UInt64(value) ?? 0
    }
}

nonisolated extension StringUInt64: ExpressibleByIntegerLiteral {
    init(integerLiteral value: UInt64) {
        self.value = value
    }

    typealias IntegerLiteralType = UInt64
}


nonisolated struct StringInt: Codable, Equatable {
    let value: Int

    init(_ value: Int) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let str = try container.decode(String.self)
        self.value = Int(str) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(String(value))
    }
}

nonisolated extension StringInt: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.value = Int(value) ?? 0
    }
}

nonisolated extension StringInt: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        self.value = value
    }

    typealias IntegerLiteralType = Int
}
