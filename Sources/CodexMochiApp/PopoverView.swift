import AppKit
import CodexMochiCore
import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: QuotaStore
    @AppStorage("mochiTheme") private var storedTheme = MochiThemeID.mint.rawValue
    @AppStorage("membershipOverride") private var storedMembershipOverride = MembershipOverride.automatic.rawValue

    private var theme: MochiThemeID {
        MochiThemeID(storedValue: storedTheme)
    }

    private var membershipOverride: MembershipOverride {
        MembershipOverride(rawValue: storedMembershipOverride) ?? .automatic
    }

    private var membership: MembershipTier {
        MembershipTier.resolved(
            detected: .detect(plan: store.snapshot?.plan),
            override: membershipOverride
        )
    }

    private var headlineRemaining: Double? {
        store.snapshot?.primaryWeekly?.remainingPercent ?? store.snapshot?.constrainedWeekly?.remainingPercent
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            VStack(spacing: 8) {
                QuotaCard(
                    eyebrow: "本周额度",
                    window: store.snapshot?.primaryWeekly,
                    fallback: stateFallback,
                    theme: theme
                )
                ResetCreditCard(
                    available: store.snapshot?.resetCreditsAvailable,
                    applicable: store.snapshot?.resetCreditsApplicable,
                    fallback: stateFallback,
                    theme: theme
                )
                LocalTokenCard(snapshot: store.localTokens, theme: theme)
            }
            .padding(.horizontal, 12)

            Color.clear.frame(height: 6)

            compactFooter
                .padding(.horizontal, 14)
                .frame(height: 42)
        }
        .frame(width: 348, height: 404, alignment: .top)
        .background(MochiPalette.paper)
    }

    private var header: some View {
        HStack(spacing: 12) {
            InteractiveMochiFace(
                remainingPercent: headlineRemaining,
                mood: store.pace.mood,
                tokenUrgency: store.localTokens.speedMood.animationUrgency,
                hasError: store.error != nil && store.snapshot == nil,
                theme: theme
            )
            .id(store.pace.mood.animationUrgency * 10 + store.localTokens.speedMood.animationUrgency)
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("CODEX MOCHI")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .tracking(1.1)
                    MembershipBadge(
                        membership: membership,
                        storedOverride: $storedMembershipOverride
                    )
                    if store.pace.mood.animationUrgency >= 3 {
                        Text("💨")
                            .font(.system(size: 10))
                    }
                }
                .foregroundStyle(MochiPalette.secondaryInk)

                Text(headline)
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MochiPalette.ink)

                Text(headerCaption)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)

            ThemePickerButton(storedTheme: $storedTheme, theme: theme)
        }
    }

    private var headline: String {
        guard let headlineRemaining else {
            return store.isRefreshing ? "正在找周口粮…" : "暂时没读到"
        }
        return "周额度还剩 \(Int(headlineRemaining.rounded()))%"
    }

    private var headerCaption: String {
        if store.isStale { return "上次结果 · 等待恢复" }
        if store.isRefreshing { return "正在刷新本周进度" }
        if store.pace.mood != .learning { return store.pace.funPhrase }
        if let plan = store.snapshot?.plan { return "\(plan) 计划 · 周额度" }
        return "正在观察本周额度"
    }

    private var accentColor: Color {
        if store.pace.mood.animationUrgency >= 4 { return MochiPalette.coral }
        return MochiPalette.accent(for: theme)
    }

    private var stateFallback: String {
        if store.isRefreshing { return "读取中" }
        return store.error?.localizedDescription ?? "暂无数据"
    }

    private var statusText: String {
        if let error = store.error { return error.localizedDescription }
        guard let fetchedAt = store.snapshot?.fetchedAt else { return "仅读取本机 Codex 登录，不保存令牌" }
        return "更新于 \(fetchedAt.formatted(date: .omitted, time: .shortened)) · 每分钟采样"
    }

    private var compactFooter: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(store.isStale || store.error != nil ? MochiPalette.yuzu : MochiPalette.mint)
                .frame(width: 6, height: 6)

            Text(statusText)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(MochiPalette.secondaryInk)
                .lineLimit(store.error == nil ? 1 : 2)
                .minimumScaleFactor(0.8)

            Spacer(minLength: 3)

            Button {
                Task { await store.refresh() }
            } label: {
                Label(store.isRefreshing ? "刷新中" : "刷新", systemImage: "arrow.clockwise")
                    .font(.system(size: 10, weight: .semibold))
            }
            .buttonStyle(FooterActionButtonStyle(tint: MochiPalette.accent(for: theme)))
            .disabled(store.isRefreshing)

            Button("退出") { NSApp.terminate(nil) }
                .font(.system(size: 10, weight: .medium))
                .buttonStyle(FooterActionButtonStyle(tint: MochiPalette.secondaryInk))
        }
    }
}

private struct FooterActionButtonStyle: ButtonStyle {
    let tint: Color
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(tint.opacity(fillOpacity(isPressed: configuration.isPressed)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(tint.opacity(strokeOpacity(isPressed: configuration.isPressed)), lineWidth: 0.75)
            )
            .opacity(isEnabled ? 1 : 0.55)
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
    }

    private func fillOpacity(isPressed: Bool) -> Double {
        guard isEnabled else { return 0.05 }
        return isPressed ? 0.16 : 0.08
    }

    private func strokeOpacity(isPressed: Bool) -> Double {
        guard isEnabled else { return 0.18 }
        return isPressed ? 0.42 : 0.26
    }
}

private struct QuotaCard: View {
    let eyebrow: String
    let window: QuotaWindow?
    let fallback: String
    let theme: MochiThemeID

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(MochiPalette.secondaryInk)
                Spacer()
                if let window {
                    Text("\(Int(window.remainingPercent.rounded()))%")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MochiPalette.ink)
                } else {
                    Text("—")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(MochiPalette.secondaryInk)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(MochiPalette.track)
                    Capsule()
                        .fill(MochiPalette.accent(for: theme))
                        .frame(width: geometry.size.width * CGFloat((window?.remainingPercent ?? 0) / 100))
                }
            }
            .frame(height: 8)

            Text(detailText)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(MochiPalette.secondaryInk)
                .lineLimit(1)
        }
        .padding(11)
        .background(cardBackground)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(MochiPalette.card)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(MochiPalette.hairline, lineWidth: 1)
            )
    }

    private var detailText: String {
        guard let window else { return fallback }
        guard let reset = window.resetsAt else { return "周重置时间暂不可用" }
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

private struct ResetCreditCard: View {
    let available: Int?
    let applicable: Int?
    let fallback: String
    let theme: MochiThemeID

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MochiPalette.accent(for: theme).opacity(0.17))
                    .frame(width: 42, height: 42)
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(MochiPalette.accent(for: theme))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("还有多少张重置卡")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(MochiPalette.secondaryInk)
                Text(available.map { "\($0) 张" } ?? "—")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MochiPalette.ink)
            }

            Spacer(minLength: 4)

            Text(detailText)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(MochiPalette.accent(for: theme))
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(MochiPalette.softCard(for: theme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MochiPalette.softHairline(for: theme), lineWidth: 1)
                )
        )
    }

    private var detailText: String {
        guard available != nil else { return fallback }
        guard let applicable else { return "储备重置卡\n当前可使用未知" }
        return "储备重置卡\n当前可使用 \(applicable) 张"
    }
}

private struct LocalTokenCard: View {
    let snapshot: LocalTokenSnapshot
    let theme: MochiThemeID

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Label("今日 Mac 口粮", systemImage: "pawprint.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                Spacer()
                Text("本机原始 Token")
                    .font(.system(size: 8.5, weight: .medium))
            }
            .foregroundStyle(MochiPalette.secondaryInk)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("今日累计")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(MochiPalette.secondaryInk)
                    Text(todayText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MochiPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().frame(height: 38)

                VStack(alignment: .leading, spacing: 3) {
                    Text("最近 15 分钟")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(MochiPalette.secondaryInk)
                    Text(rateText)
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(MochiPalette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Text(snapshot.speedMood.phrase.replacingOccurrences(of: "糯米猫", with: ""))
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundStyle(MochiPalette.accent(for: theme))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                PoppingFoodBowl(mood: snapshot.speedMood, theme: theme)
                    .frame(width: 52, height: 52)
            }

            HStack(spacing: 5) {
                Text(breakdownText)
                Spacer(minLength: 4)
                Text("不等于额度 Token")
            }
            .font(.system(size: 8.5, weight: .medium))
            .foregroundStyle(MochiPalette.secondaryInk)
            .lineLimit(1)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(MochiPalette.softCard(for: theme))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MochiPalette.softHairline(for: theme), lineWidth: 1)
                )
        )
    }

    private var todayText: String {
        guard snapshot.sampleCount > 0 else { return "等待记录" }
        return TokenCountFormatter.compact(Double(snapshot.today.total))
    }

    private var rateText: String {
        guard let rate = snapshot.recentTokensPerHour else { return "观察中" }
        if rate == 0 { return "0 / 时" }
        return TokenCountFormatter.hourly(rate)
    }

    private var breakdownText: String {
        guard snapshot.sampleCount > 0 else { return "只读取这台 Mac 的 Codex 日志" }
        return "输入 \(TokenCountFormatter.compact(Double(snapshot.today.input)))（缓存 \(TokenCountFormatter.compact(Double(snapshot.today.cachedInput)))）· 输出 \(TokenCountFormatter.compact(Double(snapshot.today.output)))"
    }
}

private struct PoppingFoodBowl: View {
    let mood: TokenSpeedMood
    let theme: MochiThemeID
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let kibbleDirections = [
        CGVector(dx: -15, dy: -24),
        CGVector(dx: 13, dy: -29),
        CGVector(dx: -24, dy: -18),
        CGVector(dx: 23, dy: -20),
        CGVector(dx: -6, dy: -34),
        CGVector(dx: 28, dy: -11),
        CGVector(dx: -29, dy: -10),
        CGVector(dx: 6, dy: -36),
    ]

    private static let sparkAngles = [-165.0, -140, -115, -90, -65, -40, -15]

    private var style: FoodBurstStyle {
        FoodBurstStyle(mood: mood)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30.0)) { timeline in
            ZStack {
                if !reduceMotion, let duration = style.cycleDuration {
                    burstParticles(at: timeline.date, duration: duration)
                }
                FoodBowlGraphic(theme: theme)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mood.phrase)
        .help(mood.phrase)
    }

    @ViewBuilder
    private func burstParticles(at date: Date, duration: Double) -> some View {
        let cycle = date.timeIntervalSinceReferenceDate / duration

        ForEach(0..<style.kibbleCount, id: \.self) { index in
            let progress = particleProgress(cycle: cycle, index: index, count: style.kibbleCount)
            KibbleBurstParticle(
                progress: progress,
                direction: Self.kibbleDirections[index % Self.kibbleDirections.count],
                strength: style.travelStrength,
                rotation: Double(index * 47)
            )
        }

        ForEach(0..<style.sparkCount, id: \.self) { index in
            let progress = particleProgress(cycle: cycle, index: index, count: style.sparkCount)
            SparkBurstParticle(
                progress: progress,
                angle: Self.sparkAngles[index % Self.sparkAngles.count],
                strength: style.travelStrength,
                isFirework: style == .firework,
                color: MochiPalette.accent(for: theme)
            )
        }
    }

    private func particleProgress(cycle: Double, index: Int, count: Int) -> Double {
        let stagger = Double(index) / Double(max(1, count))
        return (cycle + stagger).truncatingRemainder(dividingBy: 1)
    }
}

private struct KibbleBurstParticle: View {
    let progress: Double
    let direction: CGVector
    let strength: Double
    let rotation: Double

    var body: some View {
        let travel = 1 - pow(1 - progress, 2)
        let arc = sin(progress * .pi) * 6

        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(MochiPalette.kibble)
            .frame(width: 7, height: 5)
            .rotationEffect(.degrees(rotation + progress * 150))
            .scaleEffect(max(0.55, 1 - progress * 0.38))
            .offset(
                x: direction.dx * travel * strength,
                y: -8 + direction.dy * travel * strength - arc
            )
            .opacity(particleOpacity)
    }

    private var particleOpacity: Double {
        if progress < 0.1 { return progress / 0.1 }
        return max(0, min(1, (1 - progress) / 0.32))
    }
}

private struct SparkBurstParticle: View {
    let progress: Double
    let angle: Double
    let strength: Double
    let isFirework: Bool
    let color: Color

    var body: some View {
        let radians = angle * .pi / 180
        let travel = 1 - pow(1 - progress, 2)
        let distance = (isFirework ? 31.0 : 21.0) * strength

        Capsule()
            .fill(color)
            .frame(width: isFirework ? 13 : 7, height: isFirework ? 2.5 : 2)
            .rotationEffect(.degrees(angle))
            .offset(
                x: cos(radians) * distance * travel,
                y: -7 + sin(radians) * distance * travel
            )
            .opacity(sparkOpacity)
    }

    private var sparkOpacity: Double {
        if progress < 0.08 { return progress / 0.08 }
        return max(0, min(1, (1 - progress) / 0.24))
    }
}

private struct FoodBowlGraphic: View {
    let theme: MochiThemeID

    var body: some View {
        ZStack {
            Ellipse()
                .fill(MochiPalette.ink.opacity(0.08))
                .frame(width: 39, height: 8)
                .offset(y: 18)

            FoodBowlShape()
                .fill(MochiPalette.accent(for: theme))
                .frame(width: 43, height: 27)
                .offset(y: 8)

            Ellipse()
                .fill(MochiPalette.paper)
                .frame(width: 40, height: 16)
                .overlay(
                    Ellipse().stroke(MochiPalette.accent(for: theme).opacity(0.65), lineWidth: 2)
                )
                .offset(y: -3)

            ZStack {
                Circle().frame(width: 7, height: 7).offset(x: -11, y: -4)
                Circle().frame(width: 8, height: 8).offset(x: 0, y: 0)
                Circle().frame(width: 7, height: 7).offset(x: 11, y: -4)
                Circle().frame(width: 6, height: 6).offset(x: -5, y: -8)
                Circle().frame(width: 6, height: 6).offset(x: 7, y: -8)
            }
            .foregroundStyle(MochiPalette.kibble)

            Image(systemName: "pawprint.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.9))
                .offset(y: 10)
        }
    }
}

private struct FoodBowlShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.76, y: rect.maxY),
            control: CGPoint(x: rect.width * 0.94, y: rect.height * 0.92)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.24, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.height * 1.04)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control: CGPoint(x: rect.width * 0.06, y: rect.height * 0.92)
        )
        path.closeSubpath()
        return path
    }
}

private struct MembershipBadge: View {
    let membership: MembershipTier
    @Binding var storedOverride: String

    var body: some View {
        Menu {
            ForEach(MembershipOverride.allCases, id: \.rawValue) { choice in
                Button {
                    storedOverride = choice.rawValue
                } label: {
                    Label(
                        menuLabel(for: choice),
                        systemImage: currentOverride == choice ? "checkmark.circle.fill" : menuIcon(for: choice)
                    )
                }
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 7.5, weight: .bold))
                Text(label)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(0.25)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .frame(height: 18)
            .background(
                Capsule().fill(color.opacity(0.14))
            )
            .overlay(
                Capsule().stroke(color.opacity(0.28), lineWidth: 0.75)
            )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("会员显示：\(label) · 点击修改")
        .accessibilityLabel("会员显示 \(label)，点击修改")
    }

    private var currentOverride: MembershipOverride {
        MembershipOverride(rawValue: storedOverride) ?? .automatic
    }

    private var label: String {
        switch membership {
        case .plus: "PLUS"
        case .pro: "PRO"
        case .pro5x: "PRO 5×"
        case .pro20x: "PRO 20×"
        case .member: "MEMBER"
        }
    }

    private var icon: String {
        switch membership {
        case .plus: "plus"
        case .pro: "diamond.fill"
        case .pro5x: "bolt.fill"
        case .pro20x: "crown.fill"
        case .member: "person.crop.circle"
        }
    }

    private var color: Color {
        switch membership {
        case .plus: MochiPalette.membershipMint
        case .pro: MochiPalette.membershipFog
        case .pro5x: MochiPalette.membershipSky
        case .pro20x: MochiPalette.membershipButter
        case .member: MochiPalette.membershipFog
        }
    }

    private func menuLabel(for choice: MembershipOverride) -> String {
        switch choice {
        case .automatic: "自动识别（当前 \(label)）"
        case .plus: "Plus"
        case .pro5x: "Pro 5x"
        case .pro20x: "Pro 20x"
        }
    }

    private func menuIcon(for choice: MembershipOverride) -> String {
        switch choice {
        case .automatic: "wand.and.stars"
        case .plus: "plus"
        case .pro5x: "bolt.fill"
        case .pro20x: "crown.fill"
        }
    }
}

private struct ThemePickerButton: View {
    @Binding var storedTheme: String
    let theme: MochiThemeID

    var body: some View {
        Menu {
            ForEach(MochiThemeID.allCases, id: \.rawValue) { choice in
                Button {
                    storedTheme = choice.rawValue
                } label: {
                    Label(
                        choice.displayName,
                        systemImage: choice == theme ? "checkmark.circle.fill" : "circle.fill"
                    )
                }
            }
        } label: {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(MochiPalette.accent(for: theme))
                .frame(width: 25, height: 25)
                .background(
                    Circle().fill(MochiPalette.accent(for: theme).opacity(0.14))
                )
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("给糯米猫换一种柔色")
        .accessibilityLabel("选择糯米猫颜色")
    }
}

private struct InteractiveMochiFace: View {
    let remainingPercent: Double?
    let mood: BurnMood
    let tokenUrgency: Int
    let hasError: Bool
    let theme: MochiThemeID

    @State private var reaction: CatReaction?
    @State private var lastReaction = CatReaction.tongue
    @State private var bounce = false
    @State private var reactionGeneration = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: react) {
            ZStack {
                MochiFace(
                    remainingPercent: remainingPercent,
                    mood: mood,
                    tokenUrgency: tokenUrgency,
                    hasError: hasError,
                    theme: theme,
                    reaction: reaction
                )

                if let reaction {
                    ReactionSprinkles(reaction: reaction, theme: theme)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(bounce ? 1.1 : 1)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help("摸摸糯米猫")
        .accessibilityLabel("摸摸糯米猫，让它做表情")
    }

    private func react() {
        guard !hasError else { return }
        let nextReaction = lastReaction.next
        lastReaction = nextReaction
        reactionGeneration += 1
        let generation = reactionGeneration

        withAnimation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.55)) {
            reaction = nextReaction
            bounce = !reduceMotion
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard generation == reactionGeneration else { return }
            withAnimation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.72)) {
                bounce = false
            }
            try? await Task.sleep(nanoseconds: 1_280_000_000)
            guard generation == reactionGeneration else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                reaction = nil
            }
        }
    }
}

private struct ReactionSprinkles: View {
    let reaction: CatReaction
    let theme: MochiThemeID

    var body: some View {
        ZStack {
            Text(reaction == .stars ? "✦" : "♥")
                .offset(x: -32, y: -32)
            Text(reaction == .grin ? "✦" : "·")
                .offset(x: 34, y: -20)
            Text(reaction == .blush ? "♡" : "✦")
                .offset(x: 30, y: 28)
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(MochiPalette.accent(for: theme))
        .allowsHitTesting(false)
    }
}

private struct MochiFace: View {
    let remainingPercent: Double?
    let mood: BurnMood
    let tokenUrgency: Int
    let hasError: Bool
    let theme: MochiThemeID
    let reaction: CatReaction?
    @State private var bob = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var speed: Double {
        switch max(mood.animationUrgency, tokenUrgency) {
        case 0: 1.45
        case 1: 1.1
        case 2: 0.75
        case 3: 0.4
        default: 0.22
        }
    }

    var body: some View {
        ZStack {
            MochiEar().fill(MochiPalette.accent(for: theme).opacity(0.95))
                .frame(width: 24, height: 25)
                .rotationEffect(.degrees(-10))
                .offset(x: -20, y: -23)
            MochiEar().fill(MochiPalette.accent(for: theme).opacity(0.95))
                .frame(width: 24, height: 25)
                .scaleEffect(x: -1, y: 1)
                .rotationEffect(.degrees(10))
                .offset(x: 20, y: -23)
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(MochiPalette.accent(for: theme).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .stroke(MochiPalette.ink.opacity(0.12), lineWidth: 1)
                )

            if hasError {
                HStack(spacing: 16) { Text("×"); Text("×") }
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MochiPalette.ink)
            } else if let reaction {
                VStack(spacing: 1) {
                    Text(reaction.eyes)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    Text(reaction.mouth)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundStyle(MochiPalette.ink)
                .offset(y: 3)
            } else {
                HStack(spacing: 17) { Capsule(); Capsule() }
                    .frame(width: 30, height: mood == .resting ? 2 : 7)
                    .foregroundStyle(MochiPalette.ink)
                    .offset(y: -2)
            }

            if reaction == nil {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(MochiPalette.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 12, height: 8)
                    .offset(y: 13)
            }
        }
        .offset(y: bob ? -2 : 2)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: speed).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
        .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        guard let remainingPercent else { return "糯米猫周额度节奏状态" }
        return "糯米猫，主周额度剩余 \(Int(remainingPercent.rounded())) 百分比"
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
    static let sky = Color(red: 0.28, green: 0.58, blue: 0.88)
    static let mint = Color(red: 0.45, green: 0.84, blue: 0.69)
    static let yuzu = Color(red: 0.94, green: 0.69, blue: 0.22)
    static let coral = Color(red: 0.96, green: 0.37, blue: 0.34)
    static let kibble = Color(red: 0.60, green: 0.38, blue: 0.22)
    static let membershipMint = Color(red: 0.45, green: 0.84, blue: 0.69)
    static let membershipSky = Color(red: 0.46, green: 0.74, blue: 0.92)
    static let membershipButter = Color(red: 0.89, green: 0.79, blue: 0.44)
    static let membershipFog = Color(red: 0.66, green: 0.71, blue: 0.77)

    static func accent(for theme: MochiThemeID) -> Color {
        Color(red: theme.accent.red, green: theme.accent.green, blue: theme.accent.blue)
    }

    static func softCard(for theme: MochiThemeID) -> Color {
        accent(for: theme).opacity(0.10)
    }

    static func softHairline(for theme: MochiThemeID) -> Color {
        accent(for: theme).opacity(0.34)
    }

}
