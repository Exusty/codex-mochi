# Bilingual README Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current Chinese-first summary README with a complete single-file Chinese and English project guide that accurately documents the latest Codex Mochi release.

**Architecture:** Keep all public documentation in `README.md` with stable HTML anchors for language navigation. Mirror the information hierarchy across Chinese and English while using natural copy in each language, and verify every technical statement against the current Swift sources, `Package.swift`, and `scripts/build_app.sh`.

**Tech Stack:** GitHub Flavored Markdown, Swift 6 package metadata, macOS shell commands

## Global Constraints

- Keep one `README.md`; Chinese comes first and English second.
- Use stable `readme-zh` and `readme-en` anchors at the top and before each language section.
- Document only capabilities present in the current source tree.
- Use the exact repository URL `https://github.com/Exusty/codex-mochi`.
- Use the exact supported platform `macOS 13+` and popover size `348 × 404`.
- Explain that local raw Token counts are not official quota Tokens.
- Explain that Pro 5x / Pro 20x may require manual local selection because the endpoint does not always expose the subtype.
- Do not add a screenshot until a current-version repository image exists.

---

### Task 1: Rewrite and Verify the Public README

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/plans/2026-07-19-bilingual-readme-refresh.md`

**Interfaces:**
- Consumes: behavior documented by `Sources/CodexMochiApp/PopoverView.swift`, `Sources/CodexMochiApp/StatusBarController.swift`, `Sources/CodexMochiCore/AuthLoader.swift`, `Sources/CodexMochiCore/QuotaClient.swift`, `Sources/CodexMochiCore/LocalTokenUsage.swift`, `Package.swift`, and `scripts/build_app.sh`
- Produces: a complete bilingual GitHub landing document at `README.md`

- [x] **Step 1: Run documentation contract checks and verify they fail on the old README**

```bash
rg -q '<a id="readme-zh"></a>' README.md
rg -q '<a id="readme-en"></a>' README.md
rg -q 'Star → Refresh → Quit' README.md
rg -q 'Local raw Tokens are not official quota Tokens' README.md
```

Expected: at least the English anchor and English exact phrases are absent, so the combined command set does not pass.

- [x] **Step 2: Replace `README.md` with the approved bilingual structure**

Use these exact top-level sections and facts:

```text
# Codex Mochi
badges + Chinese / English anchor navigation

<a id="readme-zh"></a>
## 中文
简介
### 为什么是 Codex Mochi
### 你会看到什么
### 安装与启动
### 使用方式
### 数据从哪里来
### 隐私
### 开发
### 当前边界
### 灵感与许可证

<a id="readme-en"></a>
## English
Introduction
### Why Codex Mochi
### What you can see
### Install and launch
### How to use it
### Where the data comes from
### Privacy
### Development
### Current limitations
### Inspiration and license
```

Both language sections must cover the menu bar remaining percentage, `348 × 404` popover, interactive cat reactions, eight soft themes, theme-linked quota UI, membership badges and overrides, reset credits, today's local raw Tokens, recent 15-minute speed, kibble/spark animation, `Star → 刷新 → 退出` / `Star → Refresh → Quit`, 60-second refresh, local-first behavior, build commands, temporary signing, endpoint and local log boundaries, and MIT attribution to Exusty.

- [x] **Step 3: Verify bilingual structure and technical facts**

```bash
set -e
rg -q '<a id="readme-zh"></a>' README.md
rg -q '<a id="readme-en"></a>' README.md
rg -q 'Star → 刷新 → 退出' README.md
rg -q 'Star → Refresh → Quit' README.md
rg -q '本机原始 Token 不等于官方额度 Token' README.md
rg -q 'Local raw Tokens are not official quota Tokens' README.md
rg -q 'https://chatgpt.com/backend-api/wham/usage' README.md
rg -q 'macOS 13+' README.md
rg -q '348 × 404' README.md
git diff --check
```

Expected: every command succeeds with no output from `git diff --check`.

- [x] **Step 4: Run the project regression suite**

```bash
swift test
```

Expected: all 35 tests pass.

- [x] **Step 5: Mark this plan complete, review the final diff, and commit**

```bash
git add README.md docs/superpowers/plans/2026-07-19-bilingual-readme-refresh.md
git diff --cached --check
git commit -m "docs: publish bilingual project guide"
```

Expected: the commit is authored by `Exusty <107248786+Exusty@users.noreply.github.com>`.

- [x] **Step 6: Push and verify the remote branch**

```bash
git push -u origin codex/weekly-rate
test "$(git rev-parse HEAD)" = "$(git ls-remote origin refs/heads/codex/weekly-rate | cut -f1)"
```

Expected: the remote `codex/weekly-rate` branch points to the new documentation commit.
