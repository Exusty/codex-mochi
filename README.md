# Codex Mochi

[![CI](https://github.com/Exusty/codex-mochi/actions/workflows/ci.yml/badge.svg)](https://github.com/Exusty/codex-mochi/actions/workflows/ci.yml)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?logo=apple)](https://github.com/Exusty/codex-mochi)
[![MIT License](https://img.shields.io/badge/license-MIT-6fbf9f.svg)](LICENSE)

一只住在 macOS 菜单栏里的 Codex 额度糯米猫。

它在菜单栏显示周额度中更紧张的**剩余额度**，点击可在紧凑的 `348 × 404` 弹窗中查看会员、主周窗口、储备重置卡、今日 Mac 原始 Token、最近速度与刷新状态。额度消耗越快，冒出的猫粮越密集；高速时带火花，最高档会猫粮与火花直溅。读取失败时不会编造数字，而会保留并标记上次的可用结果。

> A tiny animated macOS menu bar companion for Codex quota. Its compact popover shows membership, the primary weekly window, reset credits, today's raw Tokens and recent local speed, plus clear stale/error states using your existing Codex login.

灵感来自 [RunCat](https://apps.apple.com/app/runcat/id1429033973) 的环境式状态反馈，以及 [Quota Float](https://github.com/change-42-yhmm/quota-float) 的本地优先额度读取边界。本项目使用独立实现与原创的糯米猫界面。

## 功能

- 菜单栏实时剩余百分比
- 可点击互动、会轮换爱心/星星/害羞等表情的糯米猫
- 8 套可持久保存的柔色主题：薄荷、晴空、薰衣草、樱花、蜜桃、奶油、燕麦、雾蓝
- Plus / Pro 会员徽章；Pro 5x 与 Pro 20x 可点击徽章手动指定并保存在本机
- 主周额度卡片、重置倒计时与储备重置卡数量
- 从本机 Codex 会话日志统计今日输入、缓存输入、输出与总 Token
- 最近 15 分钟 Token 速度，以及从“偶尔冒粮”逐级升级到“火花直溅”的爆猫粮动效
- 无多余留白的 `348 × 404` 紧凑弹窗，以及清晰带框的刷新/退出按钮
- 60 秒自动刷新、手动刷新与诚实的异常状态
- 原生 Swift / AppKit / SwiftUI，无第三方运行时依赖
- 本地优先、无遥测、不持久化 Codex 凭据

## 直接使用

```bash
./scripts/build_app.sh
open dist/CodexMochi.app
```

构建完成后也可以把 `dist/CodexMochi.app` 拖入“应用程序”文件夹。它是菜单栏应用，不会显示 Dock 图标；点击菜单栏图标打开额度卡片，再使用底部按钮刷新或退出。

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
- 重置卡只读取接口随额度返回的数量，不会兑换、消费或修改重置卡。
- Token 统计只解析 `~/.codex/sessions` 中已有的 `token_count` 事件，不上传或修改会话日志。
- 不保存令牌、账户 ID、原始响应、提示词或聊天历史。
- 会员倍数的手动选择只保存在本机偏好中，不参与额度或 Token 计算。
- 不包含遥测、统计、自动更新，也不会兑换重置额度或修改账户。
- 每 60 秒刷新一次；网络异常时显示明确状态。
- 今日 Token 仅覆盖这台 Mac 可见且已持久化的 Codex 会话；它是原始 Token，不等于官方额度 Token。

## 第一版边界

目前只支持 Codex，不包含多账户、历史曲线、通知、自启动和主题商店。额度接口可自动区分 Plus 与 Pro，但 Pro 账户可能不提供 5x / 20x 子类型，因此应用不会猜测倍数，而是允许本机手动选择。

## License

[MIT](LICENSE) © 2026 Exusty
