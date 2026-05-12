//
//  SmsScreen.swift
//  F50
//
//  Created by Nekilc on 2025/9/27.
//

import SwiftUI

struct SmsScreen: View {
    @Environment(GlobalStore.self) var g: GlobalStore

    @State private var selectedMessageID: GroupedMessage.ID?
    @State private var sendText: String = ""
    @State private var isSending: Bool = false

    private var messages: [SmsMessage] {
        g.smsMessages?.messages ?? []
    }

    private var groupedMessages: [GroupedMessage] {
        groupSMS(messages: messages)
    }

    private var selectedMessage: GroupedMessage? {
        groupedMessages.first(where: { $0.id == selectedMessageID }) ?? groupedMessages.first
    }

    private var totalUnreadCount: UInt64 {
        groupedMessages.reduce(0) { $0 + $1.unread }
    }

    var body: some View {
        HSplitView {
            messageListView
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 280)
            messageDetailView
        }
        .task {
            g.refreshSmsList()
        }
    }

    @ViewBuilder
    private var messageListView: some View {
        List(groupedMessages, selection: $selectedMessageID) { msg in
            MessageListRow(msg: msg)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteAllMessages(for: msg.number)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .onTapGesture {
                    selectedMessageID = msg.id
                    markAsRead(msg)
                }
        }
        .listStyle(.plain)
        .overlay(alignment: .top) {
            if totalUnreadCount > 0 {
                Text("\(totalUnreadCount) unread")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue.opacity(0.9))
                    .foregroundStyle(.white)
                    .clipShape(.capsule)
                    .padding(.top, 8)
            }
        }
    }

    @ViewBuilder
    private var messageDetailView: some View {
        ZStack(alignment: .bottom) {
            if let selected = selectedMessage {
                VStack(spacing: 0) {
                    messageContentView(selected)
                    sendBarView(selected)
                }
            } else {
                ContentUnavailableView(
                    "No Message Selected",
                    systemImage: "message",
                    description: Text("Select a message to view its contents")
                )
            }
        }
    }

    @ViewBuilder
    private func messageContentView(_ msg: GroupedMessage) -> some View {
        List {
            ForEach(msg.sortedMessages) { sms in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(sms.dateValue?.formatted(date: .abbreviated, time: .shortened) ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        if !sms.tag.isReaded() {
                            Text("New")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue)
                                .foregroundStyle(.white)
                                .clipShape(.capsule)
                        }
                    }
                    Text(sms.decodedContent)
                        .textSelection(.enabled)
                }
                .padding(.vertical, 4)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        deleteMessage(sms)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private func sendBarView(_ msg: GroupedMessage) -> some View {
        HStack(spacing: 12) {
            TextField("Message", text: $sendText, prompt: Text("Text"))
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .glassEffect(in: .capsule)

            Button {
                sendSms(to: msg.number)
            } label: {
                if isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .disabled(sendText.isEmpty || isSending)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private func sendSms(to number: String) {
        guard !sendText.isEmpty else { return }
        isSending = true
        Task {
            let result = await SendSms(number: number, message: sendText).set(g.zteSvc)
            await MainActor.run {
                isSending = false
                if case .success = result {
                    sendText = ""
                    g.refreshSmsList()
                }
            }
        }
    }

    private func markAsRead(_ msg: GroupedMessage) {
        guard msg.unread > 0 else { return }
        Task {
            var setter = SetMsgRead(msg_id: "", tag: 0)
            for sms in msg.sortedMessages where !sms.tag.isReaded() {
                setter.appendMsgId(id: sms.id)
            }
            _ = await setter.set(g.zteSvc)
            await MainActor.run {
                g.refreshSmsList()
            }
        }
    }

    private func deleteMessage(_ sms: SmsMessage) {
        Task {
            _ = await DeleteSms(msg_id: sms.id, notCallback: true).set(g.zteSvc)
            await MainActor.run {
                g.refreshSmsList()
            }
        }
    }

    private func deleteAllMessages(for number: String) {
        Task {
            for sms in groupedMessages.first(where: { $0.number == number })?.sortedMessages ?? [] {
                _ = await DeleteSms(msg_id: sms.id, notCallback: true).set(g.zteSvc)
            }
            await MainActor.run {
                g.refreshSmsList()
            }
        }
    }
}

private struct MessageListRow: View {
    let msg: GroupedMessage

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Image(systemName: "person.crop.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                if msg.unread > 0 {
                    Circle()
                        .fill(.blue)
                        .frame(width: 10, height: 10)
                        .offset(x: 14, y: -14)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(msg.number)
                    .font(.headline)
                    .lineLimit(1)
                Text(msg.sortedMessages.last?.decodedContent ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct SendSms: Setter {
    let number: String
    let message: String

    static func goformid() -> GoFormIds { .SEND_SMS }

    enum CodingKeys: String, CodingKey {
        case number = "Number"
        case message = "Message"
        case sms_async
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(number, forKey: .number)
        try container.encode(message, forKey: .message)
        try container.encode("0", forKey: .sms_async)
    }
}

#Preview {
    SmsScreen()
}
