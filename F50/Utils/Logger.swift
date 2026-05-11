import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "app.F50"

    static let zteService = Logger(subsystem: subsystem, category: "ZTEService")
    static let globalStore = Logger(subsystem: subsystem, category: "GlobalStore")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let auth = Logger(subsystem: subsystem, category: "Auth")
    static let helper = Logger(subsystem: "app.F50.Helper", category: "Helper")
}
