//
//  SMS.swift
//  F50
//
//  Created by Nekilc on 2025/9/27.
//

import Foundation

struct SmsCapacityInfo: Decodable {
    let sms_nv_draftbox_total: StringUInt64
    let sms_nv_rev_total: UInt64
    let sms_nv_send_total: UInt64
    let sms_nv_total: StringUInt64
    let sms_sim_draftbox_total: StringUInt64
    let sms_sim_rev_total: StringUInt64
    let sms_sim_send_total: StringUInt64
    let sms_sim_total: StringUInt64

    static func get(zteSvc: ZTEService) async throws -> SmsCapacityInfo {
        try await zteSvc.get_cmd(cmds: [.sms_capacity_info]).0
    }
}

enum SmsTag: String, Codable {
    case Readed = "0"
    case Unread = "1"
    case Draft = "3"

    func isReaded() -> Bool {
        self == .Readed
    }
}

struct SmsMessage: Decodable, Identifiable {
    let content: String
    let date: String // 25,09,27,03,02,24,+0800
    let draft_group_id: String
    let id: String
    let number: String
    let tag: SmsTag

    var decodedContent: String {
        if !content.isEmpty {
            String(data: Data(base64Encoded: content)!, encoding: .utf8)!
        } else {
            ""
        }
    }

    var dateValue: Date {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyMMddHHmmssZ"
        return parser.date(from: date.replacingOccurrences(of: ",", with: ""))!
    }
}

struct SmsMessages: Decodable {
    struct PagePrams: Encodable {
        let page: UInt64
        let data_per_page: UInt64
        let mem_store: UInt8Bool
        let tags: UInt64
        let order_by: String
    }

    let messages: [SmsMessage]

    static func get(zteSvc: ZTEService) async throws -> SmsMessages {
        try await zteSvc.get_cmd(cmds: [.sms_data_total]).0
    }
}

struct GroupedMessage: Identifiable {
    var id: String {
        number
    }

    let number: String
    var unread: UInt64

    var sortedMessages: [SmsMessage]

    var lastDate: Date {
        sortedMessages.last!.dateValue
    }
}

func groupSMS(messages: [SmsMessage]) -> [GroupedMessage] {
    var g: [String: GroupedMessage] = [:]

    for message in messages {
        if g.contains(where: { $0.key == message.number }) {
            g[message.number]?.sortedMessages.append(message)
            if message.tag.isReaded() {
                g[message.number]?.unread += 1
            }
        } else {
            g[message.number] = GroupedMessage(number: message.number, unread: 0, sortedMessages: [message])
        }
        g[message.number]?.sortedMessages.sort { $0.dateValue < $1.dateValue }
    }
    return g.values.sorted { $0.lastDate > $1.lastDate }
}
