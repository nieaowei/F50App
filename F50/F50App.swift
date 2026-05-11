//
//  F50App.swift
//  F50
//
//  Created by Nekilc on 2025/9/21.
//

import SwiftData
import SwiftUI
import OSLog

import ServiceManagement

func registerHelper() {
    let bundleID = "app.F50.Helper"
    do {
        let svc = SMAppService.loginItem(identifier: bundleID)
        try svc.register()
        Logger.ui.debug("Helper registered: \(svc.status.rawValue)")
    } catch {
        Logger.ui.error("Failed to register helper: \(error.localizedDescription)")
    }
}

private func findHelperURL() -> URL? {
    let mainAppURL = Bundle.main.bundleURL
    let helperURL = mainAppURL
        .appendingPathComponent("Contents")
        .appendingPathComponent("Library")
        .appendingPathComponent("LoginItems")
        .appendingPathComponent("Helper.app")

    return FileManager.default.fileExists(atPath: helperURL.path) ? helperURL : nil
}

private func checkHelperStatus() -> Bool {
    let runningApps = NSWorkspace.shared.runningApplications
    return runningApps.contains {
        $0.bundleIdentifier == "app.F50.Helper"
    }
}

func startHelper() {
    guard let helperURL = findHelperURL() else {
        Logger.ui.error("Helper app not found in bundle")
        return
    }
    let conf = NSWorkspace.OpenConfiguration()
    conf.activates = false
    conf.hides = false
    conf.createsNewApplicationInstance = false
    NSWorkspace.shared.openApplication(at: helperURL, configuration: conf)
    Logger.ui.debug("Helper app launched")
}

@main
struct F50App: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @AppStorage("defaultUrl")
    var defaultUrl: String = "http://192.168.0.1"

    @AppStorage("gatewayPassword")
    var gatewayPassword: String = "admin"

    var g: GlobalStore? {
        guard let url = URL(string: defaultUrl) else { return nil }
        let zte = ZTEService(host: url, headers: ["Referer": defaultUrl])
        return GlobalStore(zteSvc: zte)
    }

    init() {
        Logger.ui.debug("App launching")
        if !checkHelperStatus() {
            Logger.ui.debug("Helper not running, starting...")
            startHelper()
        } else {
            Logger.ui.debug("Helper already running")
        }
    }

    @State var enter = false

    var body: some Scene {
        WindowGroup {
            if enter, let g {
                ContentView()
                    .environment(g)
            } else {
                WelcomeScreen(defaultUrl: $defaultUrl) { url, password in
                    gatewayPassword = password
                    enter = true
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
