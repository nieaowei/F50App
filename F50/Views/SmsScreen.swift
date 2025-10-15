//
//  SmsScreen.swift
//  F50
//
//  Created by Nekilc on 2025/9/27.
//

import SwiftUI

struct SmsScreen: View {
    @Environment(GlobalStore.self) var g: GlobalStore

    var messages: [SmsMessage] {
        g.smsMessages?.messages ?? []
    }

    var groupedMessages: [GroupedMessage] {
        groupSMS(messages: messages)
    }

    @State private var selectedMessageID: GroupedMessage.ID?

    private var selectedMessage: GroupedMessage? {
        groupedMessages.first(where: { $0.id == selectedMessageID })
    }

    var body: some View {
        NavigationSplitView {
            List(groupedMessages, selection: $selectedMessageID) { msg in
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text(verbatim: msg.number).font(.headline)
//                        Text(verbatim: msg.decodedContent).font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }
        } detail: {
            if let selectedMessage {
                List(selectedMessage.sortedMessages) { msg in
                    VStack {
                        Text(verbatim: msg.dateValue.description).font(.subheadline).foregroundColor(.secondary)
                        Text(verbatim: msg.decodedContent)
                    }
                }
            } else {
                Text("Select a message")
            }
        }
//        .padding(.top, 0.5)
        .task {
            g.refreshSmsList()
        }
    }
}

#Preview {
    SmsScreen()
}
