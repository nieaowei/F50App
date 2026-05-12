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

    static func get(zteSvc: ZTEService) async -> Result<SmsCapacityInfo, Error> {
        await zteSvc.get_cmd(cmds: [.sms_capacity_info]).map(\.0)
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
        guard !content.isEmpty,
              let data = Data(base64Encoded: content),
              let decoded = String(data: data, encoding: .utf8)
        else {
            return ""
        }
        return decoded
    }

    var dateValue: Date? {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyMMddHHmmssZ"
        return parser.date(from: date.replacingOccurrences(of: ",", with: ""))
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

    static func get(zteSvc: ZTEService) async -> Result<SmsMessages, Error> {
        await zteSvc.get_cmd(cmds: [.sms_data_total]).map(\.0)
    }
}

struct GroupedMessage: Identifiable {
    var id: String {
        number
    }

    let number: String
    var unread: UInt64

    var sortedMessages: [SmsMessage]

    var lastDate: Date? {
        sortedMessages.last?.dateValue ?? nil
    }
}

func groupSMS(messages: [SmsMessage]) -> [GroupedMessage] {
    var g: [String: GroupedMessage] = [:]

    for message in messages {
        if g.contains(where: { $0.key == message.number }) {
            g[message.number]?.sortedMessages.append(message)
            if !message.tag.isReaded() {
                g[message.number]?.unread += 1
            }
        } else {
            let unread: UInt64 = message.tag.isReaded() ? 0 : 1
            g[message.number] = GroupedMessage(number: message.number, unread: unread, sortedMessages: [message])
        }
        g[message.number]?.sortedMessages.sort {
            ($0.dateValue ?? .distantPast) < ($1.dateValue ?? .distantPast)
        }
    }
    return g.values.sorted {
        ($0.lastDate ?? .distantPast) > ($1.lastDate ?? .distantPast)
    }
}

struct SetMsgRead: Setter {
    private var msg_id: String
    let tag: UInt64

    static func goformid() -> GoFormIds { .SET_MSG_READ }
    
    mutating func appendMsgId(id: String){
        self.msg_id += "\(id);"
    }
    
    init(msg_id: String, tag: UInt64) {
        self.msg_id = msg_id
        self.tag = tag
    }
}

struct DeleteSms: Setter {
    private var msg_id: String
    let notCallback: Bool

    static func goformid() -> GoFormIds { .DELETE_SMS }
    
    mutating func appendMsgId(id: String){
        self.msg_id += "\(id);"
    }
    
    init(msg_id: String, notCallback: Bool) {
        self.msg_id = msg_id
        self.notCallback = notCallback
    }
}
