//
//  HelperApp.swift
//  Helper
//
//  Created by Nekilc on 2025/9/28.
//

import SwiftUI
import SwiftData



struct MenuBar: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Wi-Fi 开关
            Toggle(isOn: .constant(false)) {
                Text("Wi-Fi")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)

            Toggle(isOn: .constant(false)) {
                Text("Cellular")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .toggleStyle(.switch)

            Divider()

            Section {} header: {
                Text("Wi-Fi")
                    .foregroundColor(.secondary)
            }
            Divider()

            Section {} header: {
                Text("蜂窝")
                    .foregroundColor(.secondary)
            }

            // 高级菜单
            Menu("高级") {
                Button("网络偏好设置…") {
                    print("打开网络偏好设置")
                }
                Button("帮助") {
                    print("显示帮助")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(width: 220) // 固定菜单窗口宽度
        .padding(.horizontal)
        .padding(.vertical, 8)
        .glassEffect(.identity, in: .rect)
    }
}


@main
struct HelperApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        MenuBarExtra {
            MenuBar()
        } label: {
            Text(verbatim: "F50")
        }

    }
}
