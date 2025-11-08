//
//  WelcomScreen.swift
//  F50
//
//  Created by Nekilc on 2025/11/4.
//

import SwiftUI

struct WelcomeScreen: View {
    @AppStorage("defaultUrl")
    var defaultUrl: String = "http://192.168.0.1"

    var onConfirm: () -> Void

    var body: some View {
        VStack {
            TextField("Gateway Address", text: $defaultUrl)
            Button("Confirm") {
                onConfirm()
            }
        }
        .padding(.all)
    }
}
