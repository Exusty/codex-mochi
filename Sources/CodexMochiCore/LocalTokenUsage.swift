import Foundation

public struct TokenCounts: Codable, Equatable, Sendable {
    public let input: Int64
    public let cachedInput: Int64
    public let output: Int64
    public let reasoningOutput: Int64
    public let total: Int64

    public init(
        input: Int64,
        cachedInput: Int64,
        output: Int64,
        reasoningOutput: Int64,
        total: Int64
    ) {
        self.input = max(0, input)
        self.cachedInput = max(0, cachedInput)
        self.output = max(0, output)
        self.reasoningOutput = max(0, reasoningOutput)
        self.total = max(0, total)
    }

    public static let zero = TokenCounts(
        input: 0,
        cachedInput: 0,
        output: 0,
        reasoningOutput: 0,
        total: 0
    )

    fileprivate static func + (lhs: TokenCounts, rhs: TokenCounts) -> TokenCounts {
        TokenCounts(
            input: lhs.input + rhs.input,
            cachedInput: lhs.cachedInput + rhs.cachedInput,
            output: lhs.output + rhs.output,
            reasoningOutput: lhs.reasoningOutput + rhs.reasoningOutput,
            total: lhs.total + rhs.total
        )
    }

    fileprivate func increment(after previous: TokenCounts?) -> TokenCounts {
        guard let previous else { return self }
        return TokenCounts(
            input: Self.positiveDelta(input, after: previous.input),
            cachedInput: Self.positiveDelta(cachedInput, after: previous.cachedInput),
            output: Self.positiveDelta(output, after: previous.output),
            reasoningOutput: Self.positiveDelta(reasoningOutput, after: previous.reasoningOutput),
            total: Self.positiveDelta(total, after: previous.total)
        )
    }

    private static func positiveDelta(_ current: Int64, after previous: Int64) -> Int64 {
        current >= previous ? current - previous : current
    }
}

public struct LocalTokenEvent: Equatable, Sendable {
    public let sessionID: String
    public let date: Date
    public let cumulative: TokenCounts

    public init(sessionID: String, date: Date, cumulative: TokenCounts) {
        self.sessionID = sessionID
        self.date = date
        self.cumulative = cumulative
    }
}

public enum TokenSpeedMood: Equatable, Sendable {
    case learning
    case resting
    case nibbling
    case munching
    case gobbling
    case flying

    public init(ratePerHour: Double?) {
        guard let ratePerHour else {
            self = .learning
            return
        }
        switch ratePerHour {
        case ...0: self = .resting
        case ..<100_000: self = .nibbling
        case ..<1_000_000: self = .munching
        case ..<5_000_000: self = .gobbling
        default: self = .flying
        }
    }

    public var phrase: String {
        switch self {
        case .learning: "糯米猫在找今天的饭碗"
        case .resting: "糯米猫舔舔爪，碗里很安静"
        case .nibbling: "糯米猫正在小口啃饼"
        case .munching: "糯米猫认真嚼着口粮"
        case .gobbling: "糯米猫抱着饭碗猛吃"
        case .flying: "糯米猫把猫粮和火花直溅出去"
        }
    }

    public var animationUrgency: Int {
        switch self {
        case .learning, .resting: 0
        case .nibbling: 1
        case .munching: 2
        case .gobbling: 3
        case .flying: 4
        }
    }
}

public struct LocalTokenSnapshot: Equatable, Sendable {
    public let today: TokenCounts
    public let recentTokensPerHour: Double?
    public let speedMood: TokenSpeedMood
    public let sampleCount: Int
    public let lastUpdatedAt: Date?

    public init(
        today: TokenCounts,
        recentTokensPerHour: Double?,
        speedMood: TokenSpeedMood,
        sampleCount: Int,
        lastUpdatedAt: Date?
    ) {
        self.today = today
        self.recentTokensPerHour = recentTokensPerHour
        self.speedMood = speedMood
        self.sampleCount = sampleCount
        self.lastUpdatedAt = lastUpdatedAt
    }

    public static let empty = LocalTokenSnapshot(
        today: .zero,
        recentTokensPerHour: nil,
        speedMood: .learning,
        sampleCount: 0,
        lastUpdatedAt: nil
    )
}

public enum TokenCountFormatter {
    public static func compact(_ value: Double) -> String {
        let safeValue = max(0, value)
        if safeValue >= 100_000_000 {
            return scaled(safeValue / 100_000_000, unit: "亿")
        }
        if safeValue >= 10_000 {
            return scaled(safeValue / 10_000, unit: "万")
        }
        return grouped(Int64(safeValue.rounded()))
    }

    public static func hourly(_ value: Double) -> String {
        "\(compact(value)) / 时"
    }

    private static func scaled(_ value: Double, unit: String) -> String {
        let rounded = value.rounded()
        if value >= 100 || abs(value - rounded) < 0.05 {
            return "\(grouped(Int64(rounded))) \(unit)"
        }
        return String(format: "%.1f %@", value, unit)
    }

    private static func grouped(_ value: Int64) -> String {
        let digits = String(value)
        var result = ""
        for (index, character) in digits.reversed().enumerated() {
            if index > 0, index.isMultiple(of: 3) { result.append(",") }
            result.append(character)
        }
        return String(result.reversed())
    }
}

public enum LocalTokenUsageCalculator {
    public static func calculate(
        events: [LocalTokenEvent],
        now: Date = Date(),
        calendar: Calendar = .current,
        recentWindow: TimeInterval = 900
    ) -> LocalTokenSnapshot {
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? now
        let recentStart = max(startOfDay, now.addingTimeInterval(-recentWindow))
        var datedIncrements: [(date: Date, counts: TokenCounts)] = []

        for sessionEvents in Dictionary(grouping: events, by: \ .sessionID).values {
            var previous: TokenCounts?
            for event in sessionEvents
                .filter({ $0.date <= now })
                .sorted(by: { $0.date < $1.date })
            {
                let increment = event.cumulative.increment(after: previous)
                datedIncrements.append((event.date, increment))
                previous = event.cumulative
            }
        }

        let todayEvents = datedIncrements.filter {
            $0.date >= startOfDay && $0.date < endOfDay
        }
        guard !todayEvents.isEmpty else { return .empty }

        let today = todayEvents.reduce(TokenCounts.zero) { $0 + $1.counts }
        let recentTotal = todayEvents
            .filter { $0.date >= recentStart }
            .reduce(Int64(0)) { $0 + $1.counts.total }
        let safeWindow = max(1, recentWindow)
        let hourlyRate = Double(recentTotal) * 3_600 / safeWindow

        return LocalTokenSnapshot(
            today: today,
            recentTokensPerHour: hourlyRate,
            speedMood: TokenSpeedMood(ratePerHour: hourlyRate),
            sampleCount: todayEvents.count,
            lastUpdatedAt: todayEvents.map(\ .date).max()
        )
    }
}

public struct LocalTokenLogReader: Sendable {
    public let sessionsRoot: URL

    public static var defaultSessionsRoot: URL {
        let environment = ProcessInfo.processInfo.environment
        let codexHome = environment["CODEX_HOME"].map { URL(fileURLWithPath: $0, isDirectory: true) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex", isDirectory: true)
        return codexHome.appendingPathComponent("sessions", isDirectory: true)
    }

    public init(sessionsRoot: URL = Self.defaultSessionsRoot) {
        self.sessionsRoot = sessionsRoot
    }

    public func read(
        now: Date = Date(),
        calendar: Calendar = .current,
        recentWindow: TimeInterval = 900
    ) -> LocalTokenSnapshot {
        LocalTokenUsageCalculator.calculate(
            events: readEvents(now: now, calendar: calendar),
            now: now,
            calendar: calendar,
            recentWindow: recentWindow
        )
    }

    private func readEvents(now: Date, calendar: Calendar) -> [LocalTokenEvent] {
        let startOfDay = calendar.startOfDay(for: now)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: startOfDay) ?? startOfDay
        let directories = [
            (url: directoryURL(for: previousDay, calendar: calendar), isPreviousDay: true),
            (url: directoryURL(for: startOfDay, calendar: calendar), isPreviousDay: false),
        ]
        var events: [LocalTokenEvent] = []

        for directory in directories {
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: directory.url,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for file in files where file.pathExtension == "jsonl" {
                if directory.isPreviousDay {
                    let modifiedAt = try? file.resourceValues(forKeys: [.contentModificationDateKey])
                        .contentModificationDate
                    guard let modifiedAt, modifiedAt >= startOfDay else { continue }
                }
                guard let contents = try? String(contentsOf: file, encoding: .utf8) else { continue }
                for line in contents.split(whereSeparator: \ .isNewline) {
                    if let event = parse(line: line, sessionID: file.lastPathComponent) {
                        events.append(event)
                    }
                }
            }
        }
        return events
    }

    private func directoryURL(for date: Date, calendar: Calendar) -> URL {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return sessionsRoot
            .appendingPathComponent(String(format: "%04d", parts.year ?? 0), isDirectory: true)
            .appendingPathComponent(String(format: "%02d", parts.month ?? 0), isDirectory: true)
            .appendingPathComponent(String(format: "%02d", parts.day ?? 0), isDirectory: true)
    }

    private func parse(line: Substring, sessionID: String) -> LocalTokenEvent? {
        guard
            let data = String(line).data(using: .utf8),
            let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            root["type"] as? String == "event_msg",
            let payload = root["payload"] as? [String: Any],
            payload["type"] as? String == "token_count",
            let info = payload["info"] as? [String: Any],
            let usage = info["total_token_usage"] as? [String: Any],
            let timestamp = root["timestamp"] as? String,
            let date = parseDate(timestamp),
            let input = integer(usage["input_tokens"]),
            let total = integer(usage["total_tokens"])
        else { return nil }

        return LocalTokenEvent(
            sessionID: sessionID,
            date: date,
            cumulative: TokenCounts(
                input: input,
                cachedInput: integer(usage["cached_input_tokens"]) ?? 0,
                output: integer(usage["output_tokens"]) ?? 0,
                reasoningOutput: integer(usage["reasoning_output_tokens"]) ?? 0,
                total: total
            )
        )
    }

    private func integer(_ value: Any?) -> Int64? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else {
            return nil
        }
        return number.int64Value
    }

    private func parseDate(_ value: String) -> Date? {
        let style = Date.ISO8601FormatStyle(includingFractionalSeconds: value.contains("."))
        return try? style.parse(value)
    }
}
