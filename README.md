# Codex Mochi

[![CI](https://github.com/Exusty/codex-mochi/actions/workflows/ci.yml/badge.svg)](https://github.com/Exusty/codex-mochi/actions/workflows/ci.yml)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-111111?logo=apple)](https://github.com/Exusty/codex-mochi)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](Package.swift)
[![MIT License](https://img.shields.io/badge/license-MIT-6fbf9f.svg)](LICENSE)

<p align="center">
  <strong>一只住在 macOS 菜单栏里的 Codex 额度糯米猫。</strong><br>
  <em>A tiny, animated Codex quota companion that lives in your macOS menu bar.</em>
</p>

<p align="center">
  <a href="#readme-zh">中文</a> · <a href="#readme-en">English</a>
</p>

---

<a id="readme-zh"></a>

## 中文

Codex Mochi 是一个轻量、原生的 macOS 菜单栏应用。它使用你现有的 Codex 登录信息展示周额度剩余比例，并从这台 Mac 的本地 Codex 会话日志中统计今日原始 Token 与最近使用速度。

额度消耗越快，碗里冒出的猫粮越密集；高速时会带火花，最高档会猫粮与火花直溅。读取失败时，应用不会编造数字，而会保留并标记最后一次可用结果。

### 为什么是 Codex Mochi

- **一眼看到剩余额度：** 菜单栏常驻糯米猫图标与周额度剩余百分比。
- **紧凑但信息完整：** 点击后打开固定为 `348 × 404` 的弹窗，没有大块无效留白。
- **会互动的小猫：** 点击糯米猫会轮换爱心、星星、害羞等表情。
- **8 套柔色主题：** 薄荷、晴空、薰衣草、樱花、蜜桃、奶油、燕麦和雾蓝；主题会同步影响小猫、周额度进度条、卡片与刷新按钮。
- **可爱的速度反馈：** 根据最近 15 分钟本机 Token 速度，从安静饭碗逐级升级到爆猫粮、火花与直溅动效。
- **诚实的数据边界：** 本机原始 Token 不等于官方额度 Token，应用会明确区分两者。
- **本地优先：** 无第三方运行时、无遥测，不上传提示词或聊天历史。

### 你会看到什么

| 位置 | 显示内容 |
| --- | --- |
| 菜单栏 | 糯米猫图标，以及当前两个周窗口中更紧张的剩余额度百分比 |
| 顶部 | 互动糯米猫、会员徽章、周额度标题与柔色主题选择器 |
| 本周额度 | 主周窗口剩余比例、主题联动进度条与重置时间 |
| 重置卡 | 储备重置卡数量，以及当前可使用数量；接口未返回时显示未知 |
| 今日 Mac 口粮 | 今日输入、缓存输入、输出、总原始 Token，以及最近 15 分钟折算速度 |
| 底栏 | `Star → 刷新 → 退出`；Star 会在默认浏览器打开本项目仓库 |

会员徽章可展示 Plus、Pro 5x 或 Pro 20x。接口通常只能可靠地区分 Plus 与 Pro，未必会提供 Pro 的 5x / 20x 子类型，因此你可以点击会员徽章在本机手动选择；该选择只影响展示，不参与额度或 Token 计算。

### 安装与启动

要求：

- macOS 13 或更高版本
- Apple Command Line Tools（没有时运行 `xcode-select --install`）

从源码构建：

```bash
git clone https://github.com/Exusty/codex-mochi.git
cd codex-mochi
./scripts/build_app.sh
open dist/CodexMochi.app
```

构建完成后，可以把 `dist/CodexMochi.app` 拖入“应用程序”文件夹。它是菜单栏应用，不显示 Dock 图标。

当前构建脚本使用本机临时签名，没有 Apple 公证。首次打开若被 macOS 拦截，请在 Finder 中右键应用并选择“打开”。

### 使用方式

1. 先在这台 Mac 上登录并正常使用 Codex，让 `~/.codex/auth.json` 与本地会话日志可用。
2. 启动 Codex Mochi，点击菜单栏里的糯米猫查看详细数据。
3. 点击小猫与它互动；点击调色盘切换柔色主题。
4. 如需指定 Pro 5x / Pro 20x，点击会员徽章并选择对应展示。
5. 使用底部刷新按钮立即采样，或等待应用每 60 秒自动刷新。
6. 点击 `Star` 打开 [Codex Mochi GitHub 仓库](https://github.com/Exusty/codex-mochi)。

周额度在界面中显示为四舍五入后的整数百分比。右键菜单栏图标也可以立即刷新或退出。

### 数据从哪里来

**周额度**

- 优先读取 `$CODEX_HOME/auth.json`，否则读取 `~/.codex/auth.json`。
- 使用现有访问令牌请求 `https://chatgpt.com/backend-api/wham/usage`。
- 该地址不是面向开发者承诺稳定的公开 API，响应格式未来可能变化；应用遇到未知格式时会显示明确错误，并保留上次可用结果。
- 重置卡只读取接口随额度返回的数量，不会兑换、消费或修改重置卡。

**今日 Mac 原始 Token**

- 只解析 `~/.codex/sessions` 中已经存在的 `token_count` 事件。
- 统计当前本地日历日内的输入、缓存输入、输出与总 Token。
- 最近速度使用最近 15 分钟的正向增量折算为每小时 Token。
- 只覆盖这台 Mac 可见且已经持久化的 Codex 会话。
- 这是本地日志里的原始 Token，不是官方额度系统用于结算的额度 Token。

### 隐私

- 访问令牌只发送给上述 ChatGPT 额度地址。
- 不保存访问令牌、账户 ID、原始接口响应、提示词或聊天历史。
- 不上传或修改本地 Codex 会话日志。
- 主题与会员手动选择只保存在本机偏好中。
- 无遥测、无行为统计、无广告、无自动更新。
- 不会兑换重置额度，也不会修改你的 Codex 账户。

### 开发

项目使用 Swift 6、AppKit 与 SwiftUI，不依赖 Xcode 工程或第三方 Swift 包：

```bash
swift test
swift build -c release
./scripts/build_app.sh
```

当前测试覆盖额度解析、接口错误、状态栏文案、会员展示、主题、互动表情、速度分级、本地 Token 聚合和 GitHub 项目链接。

欢迎通过 [Issues](https://github.com/Exusty/codex-mochi/issues) 提交问题或建议，也欢迎 Pull Request。

### 当前边界

当前版本只支持 Codex，尚未提供多账户、历史曲线、通知、登录时启动、自动更新或主题商店。应用界面目前以中文为主。

Plus / Pro 通常可以自动区分，但 Pro 5x / Pro 20x 不能保证自动识别；应用不会根据消耗速度猜测套餐倍数。

### 灵感与许可证

灵感来自 [RunCat](https://apps.apple.com/app/runcat/id1429033973) 的环境式状态反馈，以及 [Quota Float](https://github.com/change-42-yhmm/quota-float) 的本地优先额度读取边界。Codex Mochi 使用独立实现与原创的糯米猫界面。

[MIT](LICENSE) © 2026 [Exusty](https://github.com/Exusty)

<p align="right"><a href="#readme-zh">返回中文顶部</a> · <a href="#readme-en">English</a></p>

---

<a id="readme-en"></a>

## English

Codex Mochi is a lightweight, native macOS menu bar app. It uses your existing Codex sign-in to show the remaining weekly quota, then reads local Codex session logs on this Mac to summarize today's raw Tokens and recent activity speed.

The faster Tokens are consumed, the more kibble pops out of the bowl. High-speed usage adds sparks, while the fastest level sends kibble and sparks flying. If a refresh fails, Codex Mochi never invents a value: it keeps the last valid result and marks it as stale.

### Why Codex Mochi

- **Quota at a glance:** a persistent mochi-cat icon and remaining weekly percentage in the menu bar.
- **Compact but useful:** a fixed `348 × 404` popover without oversized empty areas.
- **A cat you can pet:** click the mochi cat to cycle through hearts, stars, shy faces, and other reactions.
- **Eight soft themes:** Mint, Sky, Lavender, Sakura, Peach, Butter, Oatmeal, and Fog; the selected theme also colors the cat, weekly progress bar, cards, and refresh button.
- **Playful speed feedback:** the food bowl progresses from quiet to popping kibble, sparks, and a full flying burst based on the last 15 minutes of local Token activity.
- **Honest measurement:** Local raw Tokens are not official quota Tokens, and the UI keeps those measurements separate.
- **Local-first:** no third-party runtime, no telemetry, and no upload of prompts or chat history.

### What you can see

| Area | What it shows |
| --- | --- |
| Menu bar | The mochi-cat icon and the tighter remaining percentage across the two weekly windows |
| Header | Interactive cat, membership badge, weekly quota headline, and soft-theme picker |
| Weekly quota | Primary weekly window, theme-linked progress bar, and reset time |
| Reset credits | Stored reset credits and the currently applicable count; unknown when the endpoint omits them |
| Today's Mac food | Today's input, cached input, output, total raw Tokens, and the recent 15-minute hourly rate |
| Footer | `Star → Refresh → Quit`; Star opens this repository in your default browser |

The membership badge can show Plus, Pro 5x, or Pro 20x. The endpoint can usually distinguish Plus from Pro, but it does not always expose the Pro 5x / 20x subtype. You can therefore click the badge and choose a local display override. This choice affects presentation only; it never changes quota or Token calculations.

### Install and launch

Requirements:

- macOS 13 or later
- Apple Command Line Tools (run `xcode-select --install` if needed)

Build from source:

```bash
git clone https://github.com/Exusty/codex-mochi.git
cd codex-mochi
./scripts/build_app.sh
open dist/CodexMochi.app
```

After building, you can drag `dist/CodexMochi.app` into your Applications folder. Codex Mochi is a menu bar app and does not show a Dock icon.

The build script currently applies a local ad-hoc signature and the app is not notarized by Apple. If macOS blocks the first launch, right-click the app in Finder and choose **Open**.

### How to use it

1. Sign in to and use Codex on this Mac first, so `~/.codex/auth.json` and local session logs are available.
2. Launch Codex Mochi and click the mochi cat in the menu bar to open the detailed view.
3. Click the cat to interact with it, or use the palette button to choose a soft theme.
4. If needed, click the membership badge to select Pro 5x or Pro 20x for display.
5. Use Refresh for an immediate sample, or let the app refresh automatically every 60 seconds.
6. Click `Star` to open the [Codex Mochi GitHub repository](https://github.com/Exusty/codex-mochi).

The app displays weekly quota as a rounded whole percentage. You can also right-click the menu bar item to refresh immediately or quit.

### Where the data comes from

**Weekly quota**

- Codex Mochi reads `$CODEX_HOME/auth.json` first, then falls back to `~/.codex/auth.json`.
- It sends the existing access token to `https://chatgpt.com/backend-api/wham/usage`.
- This endpoint is not a stable public developer API. Its response shape may change; unknown formats produce an explicit error while the app preserves the last valid result.
- Reset-credit values are read only when returned with quota data. The app never redeems, spends, or modifies them.

**Today's local raw Tokens**

- Codex Mochi only parses existing `token_count` events under `~/.codex/sessions`.
- It aggregates input, cached input, output, and total Tokens for the current local calendar day.
- Recent speed uses positive deltas from the last 15 minutes and converts them to an hourly rate.
- The count only covers persisted Codex sessions visible on this Mac.
- These are raw Tokens from local logs, not the quota Tokens used by the official allowance system.

### Privacy

- The access token is sent only to the ChatGPT quota endpoint listed above.
- The app does not store access tokens, account IDs, raw endpoint responses, prompts, or chat history.
- It never uploads or modifies local Codex session logs.
- Theme and membership overrides stay in local preferences.
- No telemetry, behavior analytics, advertising, or automatic updates.
- The app never redeems reset allowances or changes your Codex account.

### Development

The project uses Swift 6, AppKit, and SwiftUI. It has no Xcode project and no third-party Swift package dependency:

```bash
swift test
swift build -c release
./scripts/build_app.sh
```

The current test suite covers quota parsing, endpoint errors, menu bar copy, membership presentation, themes, cat reactions, speed levels, local Token aggregation, and the GitHub project link.

Bug reports and ideas are welcome in [Issues](https://github.com/Exusty/codex-mochi/issues), and Pull Requests are welcome too.

### Current limitations

The current version supports Codex only. It does not yet include multiple accounts, historical charts, notifications, launch at login, automatic updates, or a theme store. The app interface is currently Chinese-first.

Plus and Pro can usually be detected automatically, but reliable automatic detection of Pro 5x versus Pro 20x is not guaranteed. Codex Mochi never guesses the plan multiplier from consumption speed.

### Inspiration and license

Codex Mochi takes inspiration from [RunCat](https://apps.apple.com/app/runcat/id1429033973) for ambient status feedback and [Quota Float](https://github.com/change-42-yhmm/quota-float) for local-first quota-reading boundaries. The implementation and mochi-cat interface are original to this project.

[MIT](LICENSE) © 2026 [Exusty](https://github.com/Exusty)

<p align="right"><a href="#readme-en">Back to English top</a> · <a href="#readme-zh">中文</a></p>
