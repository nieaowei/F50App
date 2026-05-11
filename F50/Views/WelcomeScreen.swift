//
//  WelcomeScreen.swift
//  F50
//
//  Created by Nekilc on 2025/11/4.
//

import SwiftUI

struct GatewayEntry: Codable, Equatable, Hashable {
    var url: String
    var password: String
}

struct WelcomeScreen: View {
    @Binding var defaultUrl: String

    @AppStorage("urlHistory")
    private var urlHistoryData: Data = Data()

    @AppStorage("gatewayPassword")
    private var savedPassword: String = ""

    @State private var inputUrl: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isChecking: Bool = false
    @State private var status: ConnectionStatus = .idle
    @State private var urlHistory: [GatewayEntry] = []

    var onConfirm: (String, String) -> Void

    enum ConnectionStatus {
        case idle, checking, connecting, loginFailed(String), failed(String)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "wifi.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)

                Text("F50 Gateway")
                    .font(.largeTitle)
                    .bold()

                Text("Configure Gateway Address")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Gateway Address")
                    .font(.headline)

                HStack {
                    TextField("http://192.168.0.1", text: $inputUrl)
                        .textFieldStyle(.roundedBorder)

                    if !urlHistory.isEmpty {
                        Menu {
                            ForEach(urlHistory, id: \.url) { entry in
                                Button(entry.url) {
                                    inputUrl = entry.url
                                    password = entry.password
                                }
                            }
                            Divider()
                            Button("Clear History", role: .destructive) {
                                urlHistory = []
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if isChecking {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                Text("Password")
                    .font(.headline)
                    .padding(.top, 4)

                HStack {
                    Group {
                        if showPassword {
                            TextField("Enter password", text: $password)
                        } else {
                            SecureField("Enter password", text: $password)
                        }
                    }
                    .textFieldStyle(.roundedBorder)

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                HStack {
                    statusView
                    Spacer()
                }
            }
            .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Button("Confirm") {
                    checkConnection()
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputUrl.isEmpty || isChecking)
                .frame(width: 200)

                if case .failed = status {
                    Button("Skip") {
                        defaultUrl = inputUrl
                        saveToHistory()
                        onConfirm(inputUrl, "")
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            inputUrl = defaultUrl
            password = savedPassword
            loadHistory()
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .idle:
            EmptyView()
        case .checking, .connecting:
            Text("Checking connection...")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .loginFailed(let msg):
            Label(msg, systemImage: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        case .failed(let msg):
            Label(msg, systemImage: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "urlHistory"),
           let history = try? JSONDecoder().decode([GatewayEntry].self, from: data) {
            urlHistory = history
        }
    }

    private func saveToHistory() {
        let entry = GatewayEntry(url: inputUrl, password: password)
        var history = urlHistory
        history.removeAll { $0.url == inputUrl }
        history.insert(entry, at: 0)
        if history.count > 10 {
            history = Array(history.prefix(10))
        }
        urlHistory = history
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "urlHistory")
        }
    }

    private func checkConnection() {
        guard !inputUrl.isEmpty else { return }

        status = .checking
        isChecking = true

        guard let url = URL(string: inputUrl.hasPrefix("http") ? inputUrl : "http://\(inputUrl)") else {
            status = .failed("Invalid URL")
            isChecking = false
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                isChecking = false
                if error != nil {
                    status = .failed("Connection failed")
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 500 {
                    attemptLogin()
                } else {
                    attemptLogin()
                }
            }
        }.resume()
    }

    private func attemptLogin() {
        status = .connecting
        isChecking = true

        let zteSvc = ZTEService(host: URL(string: inputUrl)!, headers: ["Referer": inputUrl])
        let store = GlobalStore(zteSvc: zteSvc)

        Task {
            do {
                let resp = try await store.login(password: password)
                await MainActor.run {
                    isChecking = false
                    if resp.result == .Ok {
                        defaultUrl = inputUrl
                        saveToHistory()
                        onConfirm(inputUrl, password)
                    } else {
                        status = .loginFailed("Login failed: Invalid password")
                    }
                }
            } catch {
                await MainActor.run {
                    isChecking = false
                    status = .loginFailed("Login failed: \(error.localizedDescription)")
                }
            }
        }
    }
}
