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
        groupedMessages.first(where: { $0.id == selectedMessageID }) ?? groupedMessages.first
    }

    @State private var sendText: String = ""

    var body: some View {
        VStack {
            HSplitView {
                VStack {
                    List(groupedMessages, selection: $selectedMessageID) { msg in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.footnote)
                                .foregroundStyle(msg.unread > 0 ? .blue : .clear)

                            Image(systemName: "person.crop.circle")
                                .font(.largeTitle)
                            VStack(alignment: .leading) {
                                Text(verbatim: msg.number).font(.headline)
                                Text(verbatim: msg.sortedMessages.last?.decodedContent ?? "")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 280)
                ZStack(alignment: .bottom) {
                    if let selectedMessage {
                        List(selectedMessage.sortedMessages) { msg in
                            VStack {
                                Text(verbatim: msg.dateValue.description).font(.subheadline).foregroundColor(.secondary)
                                Text(verbatim: msg.decodedContent).textSelection(.enabled)
                            }
                        }
                        HStack {
                            VStack {
                                TextField("", text: $sendText, prompt: Text("Text"))
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                            }
                            .glassEffect(in: .capsule)
//                            .padding()
//                            .controlSize(.extraLarge)

                            Button {} label: {
                                Image(systemName: "paperplane")
                                    .font(.title2)
                            }
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
//                            .controlSize(.large)
                        }
                        .padding(.all)
                    } else {
                        Text("Select a message")
                    }
                }
            }
        }

        .task {
            g.refreshSmsList()
        }
    }
}

#Preview {
    SmsScreen()
}
