import AppKit
import Combine
import CodexMochiCore
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()
    private let store = QuotaStore()
    private var cancellables = Set<AnyCancellable>()
    private var animationTimer: Timer?
    private var refreshTimer: Timer?
    private var phase = 0

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusButton()
        configurePopover()
        observeStore()
        startTimers()

        Task { await store.refresh() }
    }

    private func configureStatusButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePopover)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.imagePosition = .imageLeading
        button.imageScaling = .scaleProportionallyDown
        button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        button.toolTip = "Codex Mochi · 查看剩余额度"
        updateStatusButton()
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 348, height: 404)
        popover.contentViewController = NSHostingController(rootView: PopoverView(store: store))
    }

    private func observeStore() {
        Publishers.CombineLatest4(
            store.$snapshot,
            store.$error,
            store.$isRefreshing,
            store.$pace
        )
            .combineLatest(store.$localTokens)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateStatusButton() }
            .store(in: &cancellables)
    }

    private func startTimers() {
        animationTimer = Timer.scheduledTimer(
            timeInterval: 0.28,
            target: self,
            selector: #selector(advanceAnimation),
            userInfo: nil,
            repeats: true
        )
        refreshTimer = Timer.scheduledTimer(
            timeInterval: 60,
            target: self,
            selector: #selector(refreshQuota),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func advanceAnimation() {
        phase = (phase + 1) % 24
        updateStatusButton()
    }

    @objc private func refreshQuota() {
        Task { await store.refresh() }
    }

    private func updateStatusButton() {
        guard let button = statusItem.button else { return }
        let remaining = store.snapshot?.constrainedWeekly?.remainingPercent
        button.title = " " + StatusTitleFormatter.title(snapshot: store.snapshot, error: store.error)
        button.image = MochiIconRenderer.image(
            remainingPercent: remaining,
            burnUrgency: max(
                store.pace.mood.animationUrgency,
                store.localTokens.speedMood.animationUrgency
            ),
            phase: phase,
            hasError: store.error != nil && store.snapshot == nil,
            isLoading: store.isRefreshing && store.snapshot == nil
        )
        button.setAccessibilityLabel(accessibilityLabel(remaining: remaining))
    }

    private func accessibilityLabel(remaining: Double?) -> String {
        if let remaining {
            return "Codex 周额度剩余 \(Int(remaining.rounded())) 百分比，\(store.localTokens.speedMood.phrase)"
        }
        return store.error?.localizedDescription ?? "正在读取 Codex 周额度"
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let refresh = NSMenuItem(title: "立即刷新", action: #selector(refreshQuota), keyEquivalent: "r")
        refresh.target = self
        menu.addItem(refresh)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "退出 Codex Mochi", action: #selector(quitApplication), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func quitApplication() {
        NSApp.terminate(nil)
    }
}
