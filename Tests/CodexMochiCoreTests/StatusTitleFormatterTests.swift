import Foundation
import Testing
@testable import CodexMochiCore

@Test func statusTitleUsesRoundedFiveHourRemaining() {
    let snapshot = QuotaSnapshot(
        plan: nil,
        fiveHour: QuotaWindow(remainingPercent: 64.4, resetsAt: nil, windowSeconds: 18_000),
        weekly: QuotaWindow(remainingPercent: 20, resetsAt: nil, windowSeconds: 604_800),
        fetchedAt: Date()
    )

    #expect(StatusTitleFormatter.title(snapshot: snapshot, error: nil) == "64%")
}

@Test func statusTitleFallsBackToWeeklyAndHonestStateSymbols() {
    let weeklyOnly = QuotaSnapshot(
        plan: nil,
        fiveHour: nil,
        weekly: QuotaWindow(remainingPercent: 25.5, resetsAt: nil, windowSeconds: 604_800),
        fetchedAt: Date()
    )

    #expect(StatusTitleFormatter.title(snapshot: weeklyOnly, error: nil) == "26%")
    #expect(StatusTitleFormatter.title(snapshot: nil, error: nil) == "…")
    #expect(StatusTitleFormatter.title(snapshot: nil, error: .signedOut) == "!")
}
