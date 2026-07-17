import Foundation

public struct UsageSample: Codable, Equatable, Sendable {
    public let date: Date
    public let remainingPercent: Double

    public init(date: Date, remainingPercent: Double) {
        self.date = date
        self.remainingPercent = min(100, max(0, remainingPercent))
    }
}

public enum UsageFrequency: Equatable, Sendable {
    case learning
    case quiet
    case occasional
    case frequent
    case intense

    public var label: String {
        switch self {
        case .learning: "观察中"
        case .quiet: "安安静静"
        case .occasional: "偶尔来一口"
        case .frequent: "来得挺勤"
        case .intense: "几乎没停"
        }
    }
}

public enum BurnMood: Equatable, Sendable {
    case learning
    case resting
    case sipping
    case munching
    case gobbling
    case blazing

    public var phrase: String {
        switch self {
        case .learning: "糯米猫正在闻味道"
        case .resting: "糯米猫正在打盹"
        case .sipping: "糯米猫在小口抿茶"
        case .munching: "糯米猫认真嚼口粮"
        case .gobbling: "糯米猫正在狼吞虎咽"
        case .blazing: "糯米猫尾巴都冒烟了"
        }
    }

    public var animationUrgency: Int {
        switch self {
        case .learning, .resting: 0
        case .sipping: 1
        case .munching: 2
        case .gobbling: 3
        case .blazing: 4
        }
    }
}

public struct UsagePace: Equatable, Sendable {
    public let burnRatePerHour: Double?
    public let activeIntervals: Int
    public let observedIntervals: Int
    public let frequency: UsageFrequency
    public let mood: BurnMood
    public let projectedHoursRemaining: Double?
    public let observationMinutes: Int

    public var funPhrase: String { mood.phrase }

    public static let learning = UsagePace(
        burnRatePerHour: nil,
        activeIntervals: 0,
        observedIntervals: 0,
        frequency: .learning,
        mood: .learning,
        projectedHoursRemaining: nil,
        observationMinutes: 0
    )
}

public enum UsagePaceCalculator {
    public static func calculate(
        samples: [UsageSample],
        now: Date = Date(),
        window: TimeInterval = 3_600
    ) -> UsagePace {
        let cutoff = now.addingTimeInterval(-window)
        let recent = samples
            .filter { $0.date >= cutoff && $0.date <= now }
            .sorted { $0.date < $1.date }
        guard recent.count >= 2 else { return .learning }

        var segmentStart = 0
        for index in 1 ..< recent.count {
            if recent[index].remainingPercent - recent[index - 1].remainingPercent >= 1 {
                segmentStart = index
            }
        }
        let segment = Array(recent[segmentStart...])
        guard segment.count >= 2 else { return .learning }

        let elapsed = segment.last!.date.timeIntervalSince(segment.first!.date)
        guard elapsed >= 30 else { return .learning }

        var burned = 0.0
        var activeIntervals = 0
        for index in 1 ..< segment.count {
            let drop = segment[index - 1].remainingPercent - segment[index].remainingPercent
            if drop > 0.001 {
                burned += drop
                activeIntervals += 1
            }
        }

        let hourlyRate = burned / (elapsed / 3_600)
        let frequency = frequency(activeIntervals: activeIntervals)
        let mood = mood(rate: hourlyRate)
        let remaining = segment.last?.remainingPercent ?? 0
        let projection = hourlyRate > 0.05 ? remaining / hourlyRate : nil

        return UsagePace(
            burnRatePerHour: hourlyRate,
            activeIntervals: activeIntervals,
            observedIntervals: segment.count - 1,
            frequency: frequency,
            mood: mood,
            projectedHoursRemaining: projection,
            observationMinutes: Int((elapsed / 60).rounded())
        )
    }

    private static func frequency(activeIntervals: Int) -> UsageFrequency {
        switch activeIntervals {
        case 0: .quiet
        case 1 ... 2: .occasional
        case 3 ... 8: .frequent
        default: .intense
        }
    }

    private static func mood(rate: Double) -> BurnMood {
        switch rate {
        case ...0.02: .resting
        case ..<0.5: .sipping
        case ..<2: .munching
        case ..<5: .gobbling
        default: .blazing
        }
    }
}

public enum UsageHistoryRecorder {
    public static func appending(
        snapshot: QuotaSnapshot,
        to samples: [UsageSample],
        retention: TimeInterval = 86_400
    ) -> [UsageSample] {
        guard let remaining = snapshot.constrainedWeekly?.remainingPercent else { return samples }
        let newSample = UsageSample(date: snapshot.fetchedAt, remainingPercent: remaining)
        var retained = samples
            .filter { $0.date >= snapshot.fetchedAt.addingTimeInterval(-retention) }
            .sorted { $0.date < $1.date }

        if let last = retained.last,
           snapshot.fetchedAt.timeIntervalSince(last.date) < 15,
           abs(last.remainingPercent - remaining) < 0.001 {
            return retained
        }
        retained.append(newSample)
        return retained
    }
}

public struct UsageHistoryRepository: Sendable {
    public let fileURL: URL

    public static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CodexMochi", isDirectory: true)
            .appendingPathComponent("usage-history.json")
    }

    public init(fileURL: URL = Self.defaultURL) {
        self.fileURL = fileURL
    }

    public func load() throws -> [UsageSample] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        return try JSONDecoder().decode([UsageSample].self, from: Data(contentsOf: fileURL))
    }

    public func save(_ samples: [UsageSample]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try JSONEncoder().encode(samples)
        try data.write(to: fileURL, options: .atomic)
    }
}
