//
//  F50App.swift
//  F50
//
//  Created by Nekilc on 2025/9/21.
//

import SwiftData
import SwiftUI

import ServiceManagement

func startHelper() {
    let bundleID = "app.F50.Helper"
//    SMAppService.
//    SMLoginItemSetEnabled(bundleID, true)
    do {
        try SMAppService.loginItem(identifier: bundleID).register()
    }
    catch{
        print(error)
    }
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

    init(){
        startHelper()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(g)
        }
        .modelContainer(sharedModelContainer)

        Window("SMS", id: "SMS") {
            SmsScreen()
                .environment(g)
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        }

    }
}
