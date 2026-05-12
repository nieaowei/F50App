# F50 Gateway Manager

macOS 状态下栏应用，用于管理 ZTE 光关/移动路由器。

## 功能

- **状态监控**：实时流量、网络类型、信号强度
- **网络设置**：Wi-Fi 配置、蜂窝数据设置、DHCP 管理
- **设备管理**：查看和管理已连接设备
- **短信**：SMS 收发和管理
- **流量管理**：流量统计和限制
- **高级设置**：Band Lock、Cell Lock、NR 配置

## 系统要求

- macOS 12.0+
- 辅助菜单栏应用（Helper）

## 构建

```bash
cd F50App.xcodeproj/.. # 项目根目录
xcodebuild -project F50.xcodeproj -scheme F50 -configuration Debug build
```

## 架构

```
F50/
├── Services/          # ZTE API 服务
├── Stores/            # GlobalStore (状态管理)
├── Models/            # 数据模型 (Codable)
├── Views/             # SwiftUI 界面
├── Extensions/        # 类型扩展
└── Utils/             # 工具类
```

## 设计概念

- `AutoCmds` / `Setter` 协议 - API 请求抽象
- `@Observable` - 响应式状态
- `async/await` - 异步网络