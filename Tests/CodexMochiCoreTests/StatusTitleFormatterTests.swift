import Foundation
import Testing
@testable import CodexMochiCore

@Test func statusTitleUsesMostConstrainedWeeklyWindow() {
    let snapshot = QuotaSnapshot(
        plan: nil,
        primaryWeekly: QuotaWindow(remainingPercent: 64.4, resetsAt: nil, windowSeconds: 604_800),
        secondaryWeekly: QuotaWindow(remainingPercent: 20, resetsAt: nil, windowSeconds: 604_800),
        fetchedAt: Date()
    )

    #expect(StatusTitleFormatter.title(snapshot: snapshot, error: nil) == "20%")
}

@Test func statusTitleSupportsSingleWeeklyWindowAndHonestStateSymbols() {
    let weeklyOnly = QuotaSnapshot(
        plan: nil,
        primaryWeekly: QuotaWindow(remainingPercent: 25.5, resetsAt: nil, windowSeconds: 604_800),
        secondaryWeekly: nil,
        fetchedAt: Date()
    )

    #expect(StatusTitleFormatter.title(snapshot: weeklyOnly, error: nil) == "26%")
    #expect(StatusTitleFormatter.title(snapshot: nil, error: nil) == "…")
    #expect(StatusTitleFormatter.title(snapshot: nil, error: .signedOut) == "!")
}
