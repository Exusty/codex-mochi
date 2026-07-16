import AppKit
import CodexMochiCore
import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: QuotaStore

    private var headlineRemaining: Double? {
        store.snapshot?.fiveHour?.remainingPercent ?? store.snapshot?.weekly?.remainingPercent
    }

    private var level: QuotaLevel {
        QuotaLevel(remainingPercent: headlineRemaining ?? 100)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 17)

            VStack(spacing: 10) {
                QuotaCard(
                    eyebrow: "5 小时口粮",
                    window: store.snapshot?.fiveHour,
                    fallback: stateFallback
                )
                QuotaCard(
                    eyebrow: "本周储备",
                    window: store.snapshot?.weekly,
                    fallback: stateFallback
                )
            }
            .padding(.horizontal, 14)

            statusLine
                .padding(.horizontal, 20)
                .padding(.top, 14)

            Divider().padding(.top, 14)

            footer
                .padding(.horizontal, 14)
                .frame(height: 52)
        }
        .frame(width: 332)
        .background(MochiPalette.paper)
    }

    private var header: some View {
        HStack(spacing: 15) {
            MochiFace(remainingPercent: headlineRemaining, hasError: store.error != nil && store.snapshot == nil)
                .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 5) {
                Text("CODEX MOCHI")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(MochiPalette.secondaryInk)

                Text(headline)
                    .font(.system(size: 25, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MochiPalette.ink)

                Text(headerCaption)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(accentColor)
            }
            Spacer(minLength: 0)
        }
    }

    private var headline: String {
        guard let headlineRemaining else {
            return store.isRefreshing ? "正在找口粮…" : "暂时没读到"
        }
        return "还剩 \(Int(headlineRemaining.rounded()))%"
    }

    private var headerCaption: String {
        if store.isStale { return "上次结果 · 等待恢复" }
        if store.isRefreshing { return "正在刷新" }
        if let plan = store.snapshot?.plan { return "\(plan) 计划 · 五小时窗口" }
        return captionForLevel
    }

    private var captionForLevel: String {
        switch level {
        case .healthy: "慢慢来，口粮充足"
        case .caution: "开始认真吃了"
        case .critical: "糯米猫有点着急"
        case .empty: "等下一轮投喂"
        }
    }

    private var accentColor: Color {
        MochiPalette.color(for: level)
    }

    private var stateFallback: String {
        if store.isRefreshing { return "读取中" }
        return store.error?.localizedDescription ?? "暂无数据"
    }

    private var statusLine: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(store.isStale || store.error != nil ? MochiPalette.yuzu : MochiPalette.mint)
                .frame(width: 7, height: 7)
            Text(statusText)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(MochiPalette.secondaryInk)
                .lineLimit(2)
            Spacer()
        }
    }

    private var statusText: String {
        if let error = store.error { return error.localizedDescription }
        guard let fetchedAt = store.snapshot?.fetchedAt else { return "仅读取本机 Codex 登录，不保存令牌" }
        return "更新于 \(fetchedAt.formatted(date: .omitted, time: .shortened)) · 60 秒自动刷新"
    }

    private var footer: some View {
        HStack(spacing: 8) {
            Button {
                Task { await store.refresh() }
            } label: {
                Label(store.isRefreshing ? "刷新中" : "立即刷新", systemImage: "arrow.clockwise")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
            .buttonStyle(.borderless)
            .disabled(store.isRefreshing)

            Spacer()

            Button("退出") { NSApp.terminate(nil) }
                .buttonStyle(.borderless)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(MochiPalette.secondaryInk)
        }
    }
}

private struct QuotaCard: View {
    let eyebrow: String
    let window: QuotaWindow?
    let fallback: String

    private var level: QuotaLevel {
        QuotaLevel(remainingPercent: window?.remainingPercent ?? 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(eyebrow)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(MochiPalette.secondaryInk)
                Spacer()
                if let window {
                    Text("\(Int(window.remainingPercent.rounded()))%")
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MochiPalette.ink)
                } else {
                    Text("—")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(MochiPalette.secondaryInk)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(MochiPalette.track)
                    Capsule()
                        .fill(MochiPalette.color(for: level))
                        .frame(width: geometry.size.width * CGFloat((window?.remainingPercent ?? 0) / 100))
                }
            }
            .frame(height: 8)

            Text(detailText)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(MochiPalette.secondaryInk)
                .lineLimit(1)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MochiPalette.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(MochiPalette.hairline, lineWidth: 1)
                )
        )
    }

    private var detailText: String {
        guard let window else { return fallback }
        guard let reset = window.resetsAt else { return "重置时间暂不可用" }
        return "\(resetDescription(reset))重置"
    }

    private func resetDescription(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "即将" }
        if interval < 86_400 {
            let hours = Int(interval) / 3_600
            let minutes = max(1, (Int(interval) % 3_600) / 60)
            return hours > 0 ? "\(hours) 小时 \(minutes) 分钟后" : "\(minutes) 分钟后"
        }
        return date.formatted(.dateTime.month(.abbreviated).day().hour().minute()) + " "
    }
}

private struct MochiFace: View {
    let remainingPercent: Double?
    let hasError: Bool
    @State private var bob = false

    private var level: QuotaLevel {
        QuotaLevel(remainingPercent: remainingPercent ?? 100)
    }

    private var speed: Double {
        switch level {
        case .healthy: 1.25
        case .caution: 0.75
        case .critical, .empty: 0.38
        }
    }

    var body: some View {
        ZStack {
            MochiEar().fill(MochiPalette.color(for: level).opacity(0.95))
                .frame(width: 24, height: 25)
                .rotationEffect(.degrees(-10))
                .offset(x: -20, y: -23)
            MochiEar().fill(MochiPalette.color(for: level).opacity(0.95))
                .frame(width: 24, height: 25)
                .scaleEffect(x: -1, y: 1)
                .rotationEffect(.degrees(10))
                .offset(x: 20, y: -23)
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(MochiPalette.color(for: level).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .stroke(MochiPalette.ink.opacity(0.12), lineWidth: 1)
                )

            if hasError {
                HStack(spacing: 16) {
                    Text("×"); Text("×")
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(MochiPalette.ink)
            } else {
                HStack(spacing: 17) {
                    Capsule(); Capsule()
                }
                .frame(width: 30, height: 7)
                .foregroundStyle(MochiPalette.ink)
                .offset(y: -2)
            }

            Circle()
                .trim(from: 0, to: 0.5)
                .stroke(MochiPalette.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 12, height: 8)
                .rotationEffect(.degrees(0))
                .offset(y: 13)
        }
        .offset(y: bob ? -2 : 2)
        .onAppear {
            withAnimation(.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
        .accessibilityLabel("糯米猫额度状态")
    }
}

private struct MochiEar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control1: CGPoint(x: rect.width * 0.18, y: rect.height * 0.28),
            control2: CGPoint(x: rect.width * 0.58, y: rect.height * 0.05)
        )
        path.closeSubpath()
        return path
    }
}

private enum MochiPalette {
    static let ink = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(calibratedWhite: 0.96, alpha: 1)
            : NSColor(calibratedRed: 0.12, green: 0.14, blue: 0.16, alpha: 1)
    })
    static let secondaryInk = Color.secondary
    static let paper = Color(nsColor: .windowBackgroundColor)
    static let card = Color(nsColor: .controlBackgroundColor)
    static let track = Color(nsColor: .separatorColor).opacity(0.32)
    static let hairline = Color(nsColor: .separatorColor).opacity(0.4)
    static let mint = Color(red: 0.45, green: 0.84, blue: 0.69)
    static let yuzu = Color(red: 0.94, green: 0.69, blue: 0.22)
    static let coral = Color(red: 0.96, green: 0.37, blue: 0.34)
    static let ash = Color(red: 0.56, green: 0.58, blue: 0.61)

    static func color(for level: QuotaLevel) -> Color {
        switch level {
        case .healthy: mint
        case .caution: yuzu
        case .critical: coral
        case .empty: ash
        }
    }
}
