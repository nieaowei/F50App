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

    @State private var selectedMessage: SmsMessage.ID?

    var body: some View {
        NavigationSplitView {
            List(messages, selection: $selectedMessage) { msg in
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.largeTitle)
                    VStack(alignment: .leading) {
                        Text(verbatim: msg.number).font(.headline)
                        Text(verbatim: msg.decodedContent).font(.subheadline).foregroundColor(.secondary)
                    }
                }
            }
        } detail: {
            if let selectedMessage {
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
