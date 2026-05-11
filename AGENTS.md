# F50 代码审查问题汇总

## 🔴 高优先级问题

### 1. 硬编码默认密码
- **文件**: `F50/F50/F50App.swift:68`
- **问题**: 默认密码"admin"硬编码
```swift
@AppStorage("gatewayPassword")
var gatewayPassword: String = "admin"  // 默认密码硬编码
```
- **建议**: 使用 Keychain 或让用户首次登录时设置

### 2. Helper App 使用硬编码地址和密码
- **文件**: `Helper/HelperApp.swift:122-124`
- **问题**: Helper 无法动态配置，完全依赖硬编码值
```swift
let host = "http://192.168.0.1"
let zte = ZTEService(host: .init(string: host)!, headers: ["Referer": host])
return GlobalStore(zteSvc: zte)
```
- **建议**: 主应用应通过某种机制（共享 UserDefaults/App Groups）向 Helper 传递配置

### 3. 静默错误处理
- **文件**: `F50/F50/Stores/GlobalStore.swift:191-196`
- **问题**: 网络错误被完全忽略
```swift
func refreshLogin(password: String) {
    Task {
        do {
            _ = try await self.login(password: password)
        } catch {}
    }
}
```
- **建议**: 添加错误日志记录或向 UI 层通知错误状态

### 4. 不安全的 HTTP URL
- **文件**: `F50/F50/F50App.swift:65`
- **问题**: 默认使用明文 HTTP
```swift
@AppStorage("defaultUrl")
var defaultUrl: String = "http://192.168.0.1"
```
- **建议**: 支持 HTTPS 验证，或至少警告用户使用不安全连接

---

## 🟡 中优先级问题

### 5. Dashboard 中点击"Access Devices"打开 SMS
- **文件**: `F50/F50/Views/DashBoardScreen.swift:80-82`
- **问题**: 导航行为与标签不符
```swift
.onTapGesture {
    openWindow(id: "SMS")
}
```
- **建议**: 修复为打开 StationMgScreen 或修改标签

### 6. DHCP 设置 Apply 按钮空实现
- **文件**: `F50/F50/Views/EndSettingsScreen.swift:46`
- **问题**: Apply 按钮没有绑定任何操作
```swift
.sectionActions {
    Button("Apply") {}  // 空实现
}
```
- **建议**: 实现 `SetDHCPSettings` 调用

### 7. WiFi 密码可能二次编码
- **文件**: `F50/F50/Views/WifiSettingsScreen.swift:117-118`
- **问题**: 如果原密码是 base64 数据会错误编码
```swift
let setter = SetAccessPointInfo(..., Password: passwordData.base64EncodedString())
```
- **建议**: 确保密码不会被重复 base64 编码

### 8. LTE Band Lock 未实现
- **文件**: `F50/F50/Views/AdvantedSettingsScreen.swift:140-151`
- **问题**: UI 显示 LTE Band 选择但未发送请求
```swift
func updateBand() {
    Task {
        var set = SetNRBandLock()  // 只有 NR，缺少 LTE
        ...
    }
}
```
- **建议**: 添加 `SetLTEBandLock` 调用

### 9. SetCellLock 结果未使用
- **文件**: `F50/F50/Views/AdvantedSettingsScreen.swift:154-156`
- **问题**: 函数创建了请求但丢弃结果
```swift
func updateLockInfo() {
    _ = SetCellLock(earfcn: .init(EARFCN), pci: .init(pci), rat: rat)
}
```
- **建议**: 调用 `.set()` 或删除此未使用的函数

### 10. 数字解析失败返回 0
- **文件**: `F50/F50/Extensions/Bool.swift:82,116`
- **问题**: 解析失败时静默返回 0，难以调试
```swift
self.value = UInt64(str) ?? 0  // 失败无提示
```
- **建议**: 使用 throwing 或返回 optional

---

## 🟢 低优先级问题

### 11. 未使用的 imports
- `F50/F50/Views/DashBoardScreen.swift:8`: `Charts` 未直接使用
- `F50/F50/Views/StationMgScreen.swift:9`: `import Combine` 未使用

### 12. 注释掉的代码未清理
- `F50/F50/Stores/GlobalStore.swift:104`: `// let lan_station_list: [StationInfo]`
- `F50/F50/Views/WifiSettingsScreen.swift:66`: `// .accessibilityLabel(...)`
- `F50/F50/Views/VolumeMgScreen.swift:25`: `// @State private var setter:...`

### 13. 类型拼写错误
- `F50/F50/Views/AdvantedSettingsScreen.swift:3`: "Advanted" → "Advanced"

### 14. WiFi ChipIndex 映射可能错误
- **文件**: `F50/F50/Views/WifiSettingsScreen.swift:97`
- **问题**: `WiFiModuleSwitch` 使用 "0"/"1" 但 `ChipIndex` 可能是 "chip1"/"chip2"
```swift
wifiSwitch = WiFiModuleSwitch(rawValue: current.ChipIndex) ?? .Off
```

### 15. 不安全的 Task.detached 使用
- **文件**: `F50/F50/Models/Station.swift:47-51`
- **问题**: actor 方法在 detached task 中调用可能有线程安全问题
```swift
static func get(zteSvc: ZTEService) async throws -> StationList {
    let decoded: StationList = try await Task.detached {
        try await zteSvc.get_cmd_by_keys().0  // actor 方法
    }.value
    return decoded
}
```

### 16. Cell Lock Sheet 的 OK 按钮空实现
- **文件**: `F50/F50/Views/AdvantedSettingsScreen.swift:132`
- **问题**: 新建 Cell Lock 对话框的确认按钮没有绑定操作

### 17. SMS 发送按钮空实现
- **文件**: `F50/F50/Views/SmsScreen.swift:71`
- **问题**: 发送 SMS 的按钮没有绑定任何操作
```swift
Button {} label: { ... }  // 空闭包
```

---

## 📝 改进建议

1. **错误处理**: 在 `GlobalStore` 的 refresh 方法中适当处理错误并通知 UI
2. **密码管理**: 考虑使用 Keychain 存储密码，不使用 UserDefaults
3. **网络配置**: 支持 HTTPS 验证，增强安全性
4. **Helper 配置**: 通过 App Groups 或 XPC 共享配置给 Helper
5. **代码清理**: 删除未使用的 imports 和注释掉的代码
6. **单元测试**: 添加网络层和模型层的测试

---

## ✅ 代码优点

1. **良好的抽象**: `AutoCmds`, `Setter` 协议设计清晰
2. **类型安全**: 大量使用 enum 和 Codable
3. **响应式设计**: 使用 `@Observable` 和 `async/await`
4. **UI 分离**: Views 与 Business Logic 分离良好
5. **扩展性**: 类型化地址 (MACAddress, IPAddress) 设计优秀

---

## 📋 待办事项

### 🔴 高优先级
- [ ] 修复硬编码默认密码 - 使用 Keychain 存储
- [ ] 修复 Helper App 硬编码地址 - 通过 App Groups 共享配置
- [ ] 添加错误处理 - GlobalStore refresh 方法错误通知

### 🟡 中优先级
- [ ] 修复 Dashboard Access Devices 点击打开 SMS
- [ ] 实现 EndSettingsScreen DHCP Apply 按钮
- [ ] 修复 WiFi 密码二次编码问题
- [ ] 实现 LTE Band Lock 功能
- [ ] 删除未使用的 updateLockInfo 函数

### 🟢 低优先级
- [ ] 修复 Cell Lock Sheet OK 按钮空实现
- [ ] 实现 SMS 发送按钮功能
- [ ] 清理未使用的 imports 和注释代码
- [ ] 修复 AdvantedSettingsScreen 拼写错误 (Advanted -> Advanced)
- [ ] 修复 WiFi ChipIndex 映射问题
- [ ] 修复 Station.swift Task.detached 线程安全问题
- [ ] StringInt/StringUInt64 解析失败返回 optional 或 throwing