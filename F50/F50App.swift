//
//  F50App.swift
//  F50
//
//  Created by Nekilc on 2025/9/21.
//

import SwiftData
import SwiftUI

import ServiceManagement

func registerHelper() {
    let bundleID = "app.F50.Helper"
    do {
        let svc = SMAppService.loginItem(identifier: bundleID)
        try svc.register()
        print(svc.status.rawValue)
    } catch {
        print(error)
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
//    let bundleID = "app.F50.Helper"
    let conf = NSWorkspace.OpenConfiguration()
    conf.activates = false
    conf.hides = false
    conf.createsNewApplicationInstance = false
    NSWorkspace.shared.openApplication(at: findHelperURL()!, configuration: conf)
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

    var g: GlobalStore = {
        let host = "http://192.168.0.1"
        let zte = ZTEService(host: .init(string: host)!, headers: ["Referer": host])
        return GlobalStore(zteSvc: zte)
    }()

    init() {
        if !checkHelperStatus() {
//            registerHelper()
            startHelper()
        }
    }

    @State var enter = false

    var body: some Scene {
        WindowGroup {
            if enter {
                ContentView()
                    .environment(g)
            } else {
                WelcomeScreen {
                    enter = true
                }
//                .toolbar(removing: .title)
//                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
//                .containerBackground(.ultraThinMaterial, for: .window)
//                .windowMinimizeBehavior(.disabled)
//                .windowResizeBehavior(.disabled)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
