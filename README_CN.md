[English](README.md)

# ipatoolUI

[ipatool](https://github.com/majd/ipatool) 的原生 SwiftUI 封装，让所有 CLI 功能触手可及。

<img width="901" height="656" alt="Screenshot 2025-11-12 alle 01 02 02" src="https://github.com/user-attachments/assets/d46f1738-c6d2-4df5-b101-802a1d63ff0f" />

## 功能特性

- Apple ID 认证（登录、信息、撤销），支持应用内处理 2FA。
- 搜索应用，查看元数据，并直接从结果中发起购买。
- 手动购买许可，列出所有可用版本，查看版本元数据。
- 下载 IPA 文件，支持可选的自动购买和目标路径选择。
- 实时命令日志，捕获标准输出/标准错误以便调试。
- 偏好设置面板，可指向自定义 `ipatool` 二进制文件，切换详细/非交互标志，以及存储钥匙串密码。

## 项目结构

- `ipatoolUI.xcodeproj` – macOS SwiftUI 应用目标（最低支持 macOS 13）。
- `ipatoolUI/` – 应用程序源代码、SwiftUI 视图、视图模型、服务和资源。
- `Resources/Assets.xcassets` – 占位符应用图标和预览资源。

## 快速开始

1. 安装 `ipatool`（例如 `brew install ipatool`）。
2. 在 Xcode 15 或更新版本中打开 `ipatoolUI.xcodeproj`。
3. 选择 *ipatoolUI* scheme 并在 macOS 13+ 上构建/运行。
4. 首次启动时，如果未自动检测到，请访问 **Settings → ipatool Binary** 确认可执行文件路径。

## 使用应用

- **认证 (Authentication)**：提供 Apple ID 凭据（密码保留在本地）并登录。使用 *Account Info* 验证当前会话或 *Revoke* 清除凭据。
- **搜索 (Search)**：查找应用，查看 bundle，并对任意结果触发购买。
- **购买 (Purchase)**：通过 bundle identifier 手动获取许可。
- **版本 (Versions)**：列出应用的每个外部版本标识符；复制 ID 以备后用。
- **下载 (Download)**：选择应用/bundle、可选版本、目标路径以及是否自动购买。进度和结果会在状态区域和日志中显示。
- **版本元数据 (Version Metadata)**：解析特定外部版本的发布详情。
- **日志 (Logs)**：检查每一个启动的 `ipatool` 命令，包含脱敏后的参数和捕获的 stdout/stderr。
- **设置 (Settings)**：配置可执行文件位置、密码、详细程度和非交互行为。

## 注意事项

- UI 始终使用 `--format json` 调用 `ipatool`，以便自动解析响应。
- 敏感标志（密码、OTP 代码、钥匙串密码）在命令日志中会被掩盖。
- 应用将复杂状态（命令历史、用户偏好）委托给 `UserDefaults`，因此重新运行会保留您的设置。
