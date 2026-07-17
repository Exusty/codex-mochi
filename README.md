# Codex Mochi

[![CI](https://github.com/Exusty/codex-mochi/actions/workflows/ci.yml/badge.svg)](https://github.com/Exusty/codex-mochi/actions/workflows/ci.yml)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?logo=apple)](https://github.com/Exusty/codex-mochi)
[![MIT License](https://img.shields.io/badge/license-MIT-6fbf9f.svg)](LICENSE)

一只住在 macOS 菜单栏里的 Codex 额度糯米猫。

它默认显示五小时窗口的**剩余额度**，点击可查看五小时和每周额度、重置时间与刷新状态。额度越紧张，猫的动作越快；读取失败时不会编造数字，而会保留并标记上次的可用结果。

> A tiny animated macOS menu bar companion for Codex quota. It shows honest five-hour and weekly remaining usage, reset times, and clear stale/error states using your existing local Codex login.

灵感来自 [RunCat](https://apps.apple.com/app/runcat/id1429033973) 的环境式状态反馈，以及 [Quota Float](https://github.com/change-42-yhmm/quota-float) 的本地优先额度读取边界。本项目使用独立实现与原创的糯米猫界面。

## 功能

- 菜单栏实时剩余百分比
- 会眨眼、跳动并随额度紧张而加速的糯米猫
- 五小时和每周额度卡片及重置倒计时
- 60 秒自动刷新、手动刷新与诚实的异常状态
- 原生 Swift / AppKit / SwiftUI，无第三方运行时依赖
- 本地优先、无遥测、不持久化 Codex 凭据

## 直接使用

```bash
./scripts/build_app.sh
open dist/CodexMochi.app
```

构建完成后也可以把 `dist/CodexMochi.app` 拖入“应用程序”文件夹。它是菜单栏应用，不会显示 Dock 图标；左键打开额度卡片，右键可立即刷新或退出。

首次打开若被 macOS 拦截，在 Finder 中右键应用并选择“打开”。当前版本使用本机临时签名，未做 Apple 公证。

## 开发

要求 macOS 13 或更高版本，以及 Apple Command Line Tools：

```bash
swift test
swift build -c release
```

项目不依赖 Xcode 工程或第三方 Swift 包。完整 Xcode 未安装时，测试目标会显式链接 Command Line Tools 自带的 Swift Testing 框架。

## 数据与隐私

- 优先读取 `$CODEX_HOME/auth.json`，否则读取 `~/.codex/auth.json`。
- 现有访问令牌只发送给 `https://chatgpt.com/backend-api/wham/usage`。
- 不保存令牌、账户 ID、原始响应、提示词或聊天历史。
- 不包含遥测、统计、自动更新，也不会兑换重置额度或修改账户。
- 每 60 秒刷新一次；网络异常时显示明确状态。

## 第一版边界

目前只支持 Codex，不包含多账户、历史曲线、通知、自启动和主题商店。视觉与功能都刻意保持小而明确，后续可在实际使用后继续调整。

## License

[MIT](LICENSE) © 2026 Exusty
