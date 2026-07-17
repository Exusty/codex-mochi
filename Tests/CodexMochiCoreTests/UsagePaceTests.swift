import Foundation
import Testing
@testable import CodexMochiCore

@Test func calculatesHourlyBurnRateAndUsageFrequency() throws {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    let samples = [
        UsageSample(date: now.addingTimeInterval(-3_600), remainingPercent: 80),
        UsageSample(date: now.addingTimeInterval(-1_800), remainingPercent: 78),
        UsageSample(date: now, remainingPercent: 76),
    ]

    let pace = UsagePaceCalculator.calculate(samples: samples, now: now)

    #expect(abs(try #require(pace.burnRatePerHour) - 4) < 0.001)
    #expect(pace.activeIntervals == 2)
    #expect(pace.observedIntervals == 2)
    #expect(pace.frequency == .occasional)
    #expect(pace.mood == .gobbling)
    #expect(abs(try #require(pace.projectedHoursRemaining) - 19) < 0.001)
    #expect(pace.funPhrase == "糯米猫正在狼吞虎咽")
}

@Test func reportsQuietFrequencyWhenQuotaDoesNotMove() throws {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    let pace = UsagePaceCalculator.calculate(samples: [
        UsageSample(date: now.addingTimeInterval(-600), remainingPercent: 88),
        UsageSample(date: now, remainingPercent: 88),
    ], now: now)

    #expect(try #require(pace.burnRatePerHour) == 0)
    #expect(pace.frequency == .quiet)
    #expect(pace.mood == .resting)
    #expect(pace.projectedHoursRemaining == nil)
}

@Test func startsFreshAfterWeeklyQuotaReset() throws {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    let pace = UsagePaceCalculator.calculate(samples: [
        UsageSample(date: now.addingTimeInterval(-3_600), remainingPercent: 10),
        UsageSample(date: now.addingTimeInterval(-1_800), remainingPercent: 100),
        UsageSample(date: now, remainingPercent: 99),
    ], now: now)

    #expect(abs(try #require(pace.burnRatePerHour) - 2) < 0.001)
    #expect(pace.activeIntervals == 1)
    #expect(pace.observedIntervals == 1)
}

@Test func needsTwoSamplesBeforeClaimingAPace() {
    let now = Date(timeIntervalSince1970: 2_000_000_000)
    let pace = UsagePaceCalculator.calculate(
        samples: [UsageSample(date: now, remainingPercent: 70)],
        now: now
    )

    #expect(pace.burnRatePerHour == nil)
    #expect(pace.frequency == .learning)
    #expect(pace.mood == .learning)
    #expect(pace.funPhrase == "糯米猫正在闻味道")
}

@Test func persistsAndLoadsUsageSamples() throws {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("CodexMochiTests-\(UUID().uuidString)", isDirectory: true)
    let url = directory.appendingPathComponent("history.json")
    defer { try? FileManager.default.removeItem(at: directory) }
    let repository = UsageHistoryRepository(fileURL: url)
    let samples = [UsageSample(date: Date(timeIntervalSince1970: 123), remainingPercent: 45.5)]

    try repository.save(samples)

    #expect(try repository.load() == samples)
}
