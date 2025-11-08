//
//  HelperApp.swift
//  Helper
//
//  Created by Nekilc on 2025/9/28.
//

import SwiftData
import SwiftUI
internal import Combine

struct WifiListButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    @State private var hover = false

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
        self.hover = hover
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(
                hover ? Color.gray.opacity(0.15) :
                    Color.clear
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

import OSLog

let logger: Logger = .init(subsystem: "app.F50.Helper", category: "menubar")

struct MenuBar: View {
    @Environment(GlobalStore.self) var g

    init() {
//        print("MenuBar Init")
        logger.info("MenuBar Init")
    }

    @State var selection: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Section {
                ProgressView(value: .init(g.volumeInfo?.used_volume_mb ?? 0), total: .init(g.volumeInfo?.data_volume_limit_size_num ?? 0)) {
                    Text("Remain: \(g.volumeInfo?.displayRemainVolume ?? "")")
                        .font(.caption)
//                    Text(verbatim: "\(g.volumeInfo?.used_volume_mb ?? 0) - \(g.volumeInfo?.data_volume_limit_size_num ?? 0)")
                }
            } header: {
                Text("Usage")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 6)
            Divider()
            Toggle(isOn: .constant(false)) {
                Text("Wi-Fi")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            .padding(.horizontal, 6)

            Toggle(isOn: .constant(false)) {
                Text("Cellular")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)
            .padding(.horizontal, 6)

            Divider()

            WifiListButton("Open Main") {
                openMainApp()
            }
        }
        .frame(width: 220) // 固定菜单窗口宽度
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .glassEffect(.identity, in: .rect)
        .task {
            g.refreshVolumeInfo()
        }
    }

    func openMainApp() {
        let mainAppBundleID = "app.F50"

        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: mainAppBundleID) {
            NSWorkspace.shared.openApplication(at: url,
                                               configuration: NSWorkspace.OpenConfiguration(),
                                               completionHandler: nil)
        }
    }
}

@main
struct HelperApp: App {
    var g: GlobalStore = {
        let host = "http://192.168.0.1"
        let zte = ZTEService(host: .init(string: host)!, headers: ["Referer": host])
        return GlobalStore(zteSvc: zte)
    }()

    var dashboard: DashboardResp? {
        g.dashboard
    }

    var toolinfo: ToolbarResp? {
        g.toolbar
    }

    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    let timer5 = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    var body: some Scene {
        MenuBarExtra {
            MenuBar()
                .environment(g)
                .task {
                    do {
                        _ = try await g.login()
                    } catch {
                        print(error)
                    }
                }
        } label: {
            HStack {
                Text(verbatim: "\(g.toolbar?.network_type.rawValue ?? "") \(toolinfo?.network_provider ?? " no service")")
                Image(systemName: "cellularbars", variableValue: Double(g.toolbar?.signalbar ?? 0) / 5)
            }
            .task {
                g.refreshToolbar()
                g.refreshLogin()
            }
            .onReceive(timer) { _ in
                g.refreshToolbar()
            }
            .onReceive(timer5) { _ in
                g.refreshLogin()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
