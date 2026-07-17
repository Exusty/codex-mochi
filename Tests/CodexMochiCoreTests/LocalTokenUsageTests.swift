import Foundation
import Testing
@testable import CodexMochiCore

private let shanghaiCalendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
    return calendar
}()

private func tokenCounts(_ total: Int64) -> TokenCounts {
    TokenCounts(
        input: total,
        cachedInput: total / 2,
        output: 0,
        reasoningOutput: 0,
        total: total
    )
}

@Test func aggregatesPositiveCumulativeDeltasWithoutCountingDuplicates() throws {
    let now = try #require(shanghaiCalendar.date(from: DateComponents(
        year: 2026, month: 7, day: 17, hour: 12
    )))
    let events = [
        LocalTokenEvent(sessionID: "session-a", date: now.addingTimeInterval(-240), cumulative: tokenCounts(100)),
        LocalTokenEvent(sessionID: "session-a", date: now.addingTimeInterval(-180), cumulative: tokenCounts(160)),
        LocalTokenEvent(sessionID: "session-a", date: now.addingTimeInterval(-120), cumulative: tokenCounts(160)),
        LocalTokenEvent(sessionID: "session-a", date: now.addingTimeInterval(-60), cumulative: tokenCounts(25)),
    ]

    let snapshot = LocalTokenUsageCalculator.calculate(
        events: events,
        now: now,
        calendar: shanghaiCalendar
    )

    #expect(snapshot.today.total == 185)
    #expect(snapshot.today.input == 185)
    #expect(snapshot.today.cachedInput == 92)
    #expect(snapshot.sampleCount == 4)
}

@Test func keepsOnlyPositiveDeltasFromTheLocalCalendarDay() throws {
    let now = try #require(shanghaiCalendar.date(from: DateComponents(
        year: 2026, month: 7, day: 17, hour: 0, minute: 10
    )))
    let start = shanghaiCalendar.startOfDay(for: now)
    let events = [
        LocalTokenEvent(sessionID: "overnight", date: start.addingTimeInterval(-60), cumulative: tokenCounts(100)),
        LocalTokenEvent(sessionID: "overnight", date: start.addingTimeInterval(60), cumulative: tokenCounts(160)),
        LocalTokenEvent(sessionID: "today", date: start.addingTimeInterval(120), cumulative: tokenCounts(25)),
    ]

    let snapshot = LocalTokenUsageCalculator.calculate(
        events: events,
        now: now,
        calendar: shanghaiCalendar
    )

    #expect(snapshot.today.total == 85)
    #expect(snapshot.sampleCount == 2)
}

@Test func calculatesRecentFifteenMinuteHourlyRate() throws {
    let now = try #require(shanghaiCalendar.date(from: DateComponents(
        year: 2026, month: 7, day: 17, hour: 12
    )))
    let events = [
        LocalTokenEvent(sessionID: "pace", date: now.addingTimeInterval(-1_200), cumulative: tokenCounts(100_000)),
        LocalTokenEvent(sessionID: "pace", date: now.addingTimeInterval(-600), cumulative: tokenCounts(200_000)),
        LocalTokenEvent(sessionID: "pace", date: now, cumulative: tokenCounts(300_000)),
    ]

    let snapshot = LocalTokenUsageCalculator.calculate(
        events: events,
        now: now,
        calendar: shanghaiCalendar,
        recentWindow: 900
    )

    #expect(snapshot.today.total == 300_000)
    #expect(snapshot.recentTokensPerHour == 800_000)
    #expect(snapshot.speedMood == .munching)
}

@Test func reportsLearningAndRestingHonestly() throws {
    let now = try #require(shanghaiCalendar.date(from: DateComponents(
        year: 2026, month: 7, day: 17, hour: 12
    )))
    let empty = LocalTokenUsageCalculator.calculate(
        events: [],
        now: now,
        calendar: shanghaiCalendar
    )
    let old = LocalTokenUsageCalculator.calculate(
        events: [
            LocalTokenEvent(
                sessionID: "old",
                date: now.addingTimeInterval(-3_600),
                cumulative: tokenCounts(50_000)
            ),
        ],
        now: now,
        calendar: shanghaiCalendar
    )

    #expect(empty.recentTokensPerHour == nil)
    #expect(empty.speedMood == .learning)
    #expect(old.recentTokensPerHour == 0)
    #expect(old.speedMood == .resting)
}

@Test func classifiesEveryCuteTokenSpeedBoundary() {
    #expect(TokenSpeedMood(ratePerHour: nil) == .learning)
    #expect(TokenSpeedMood(ratePerHour: 0) == .resting)
    #expect(TokenSpeedMood(ratePerHour: 99_999) == .nibbling)
    #expect(TokenSpeedMood(ratePerHour: 100_000) == .munching)
    #expect(TokenSpeedMood(ratePerHour: 999_999) == .munching)
    #expect(TokenSpeedMood(ratePerHour: 1_000_000) == .gobbling)
    #expect(TokenSpeedMood(ratePerHour: 4_999_999) == .gobbling)
    #expect(TokenSpeedMood(ratePerHour: 5_000_000) == .flying)
    #expect(TokenSpeedMood.flying.phrase.contains("火花直溅"))
}

@Test func logReaderSkipsMalformedLinesAndReadsTokenEvents() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let dayDirectory = root.appendingPathComponent("2026/07/17", isDirectory: true)
    try FileManager.default.createDirectory(at: dayDirectory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: root) }

    let file = dayDirectory.appendingPathComponent("rollout-test.jsonl")
    let contents = """
    not-json
    {"timestamp":"2026-07-17T04:00:00Z","type":"event_msg","payload":{"type":"agent_message"}}
    {"timestamp":"2026-07-17T04:01:00Z","type":"event_msg","payload":{"type":"token_count","info":{"total_token_usage":{"input_tokens":120,"cached_input_tokens":80,"output_tokens":20,"reasoning_output_tokens":5,"total_tokens":140}}}}
    """
    try contents.write(to: file, atomically: true, encoding: .utf8)
    let now = try #require(shanghaiCalendar.date(from: DateComponents(
        year: 2026, month: 7, day: 17, hour: 13
    )))

    let snapshot = LocalTokenLogReader(sessionsRoot: root).read(
        now: now,
        calendar: shanghaiCalendar
    )

    #expect(snapshot.today.total == 140)
    #expect(snapshot.today.cachedInput == 80)
    #expect(snapshot.sampleCount == 1)
}

@Test func missingLogDirectoryReturnsEmptySnapshot() throws {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let now = try #require(shanghaiCalendar.date(from: DateComponents(
        year: 2026, month: 7, day: 17, hour: 12
    )))

    let snapshot = LocalTokenLogReader(sessionsRoot: root).read(
        now: now,
        calendar: shanghaiCalendar
    )

    #expect(snapshot == .empty)
}

@Test func formatsLargeTokenCountsForTheMenuBarCard() {
    #expect(TokenCountFormatter.compact(9_999) == "9,999")
    #expect(TokenCountFormatter.compact(12_345) == "1.2 万")
    #expect(TokenCountFormatter.compact(1_280_000) == "128 万")
    #expect(TokenCountFormatter.compact(28_900_000) == "2,890 万")
    #expect(TokenCountFormatter.compact(100_000_000) == "1 亿")
    #expect(TokenCountFormatter.hourly(15_840_000) == "1,584 万 / 时")
}
