import Foundation

public enum QuotaParser {
    public static func parse(data: Data, now: Date = Date()) throws -> QuotaSnapshot {
        guard
            let root = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw QuotaError.changedResponse
        }

        let rateLimit = dictionary(root, keys: ["rate_limit", "rateLimit"]) ?? root
        let primaryWeekly = findWindow(
            in: rateLimit,
            directKeys: ["primary_window", "primaryWindow", "weekly_primary", "weeklyPrimary"],
            names: ["primary", "main", "weekly_primary"],
            expectedSeconds: 604_800
        )
        let secondaryWeekly = findWindow(
            in: rateLimit,
            directKeys: ["secondary_window", "secondaryWindow", "weekly_secondary", "weeklySecondary"],
            names: ["secondary", "backup", "weekly_secondary"],
            expectedSeconds: 604_800
        )

        guard primaryWeekly != nil || secondaryWeekly != nil else {
            throw QuotaError.changedResponse
        }

        let resetCredits = dictionary(
            root,
            keys: ["rate_limit_reset_credits", "rateLimitResetCredits"]
        )
        let resetCreditsAvailable = resetCredits
            .flatMap { integer($0, keys: ["available_count", "availableCount"]) }
            .map { max(0, $0) }
        let resetCreditsApplicable = resetCredits
            .flatMap { integer($0, keys: ["applicable_available_count", "applicableAvailableCount"]) }
            .map { max(0, $0) }

        let rawPlan = string(root, keys: ["plan_type", "planType", "plan"])
        return QuotaSnapshot(
            plan: rawPlan.map(displayPlan),
            primaryWeekly: primaryWeekly,
            secondaryWeekly: secondaryWeekly,
            fetchedAt: now,
            resetCreditsAvailable: resetCreditsAvailable,
            resetCreditsApplicable: resetCreditsApplicable
        )
    }

    private static func findWindow(
        in container: [String: Any],
        directKeys: [String],
        names: [String],
        expectedSeconds: Int
    ) -> QuotaWindow? {
        for key in directKeys {
            if let value = container[key] as? [String: Any], let parsed = parseWindow(value) {
                return parsed
            }
        }

        for arrayKey in ["windows", "limit_windows", "limitWindows", "limits", "buckets"] {
            guard let items = container[arrayKey] as? [[String: Any]] else { continue }
            for item in items {
                guard let parsed = parseWindow(item) else { continue }
                let label = string(item, keys: ["name", "type", "id", "window", "label"])?.lowercased()
                let nameMatches = label.map { value in names.contains { value.contains($0) } } ?? false
                let durationMatches = abs(parsed.windowSeconds - expectedSeconds) <= 60
                if label != nil ? nameMatches : durationMatches { return parsed }
            }
        }
        return nil
    }

    private static func parseWindow(_ value: [String: Any]) -> QuotaWindow? {
        let remainingKeys = [
            "remaining_percent", "remainingPercent", "remaining_pct", "remainingPct",
            "remaining_ratio", "remainingRatio", "remaining",
        ]
        let usedKeys = [
            "used_percent", "usedPercent", "used_pct", "usedPct", "used_ratio",
            "usedRatio", "utilization", "used",
        ]

        let remaining: Double
        if let field = number(value, keys: remainingKeys) {
            remaining = scaled(field.value, for: field.key)
        } else if let field = number(value, keys: usedKeys) {
            remaining = 100 - scaled(field.value, for: field.key)
        } else {
            return nil
        }

        let reset = date(value, keys: [
            "reset_at", "resetAt", "resets_at", "resetsAt", "reset_time", "resetTime",
        ])
        let seconds = integer(value, keys: [
            "limit_window_seconds", "limitWindowSeconds", "window_seconds", "windowSeconds",
            "duration_seconds", "durationSeconds", "period_seconds", "periodSeconds",
        ]) ?? 0
        return QuotaWindow(remainingPercent: remaining, resetsAt: reset, windowSeconds: seconds)
    }

    private static func scaled(_ value: Double, for key: String) -> Double {
        let lower = key.lowercased()
        if lower.contains("ratio") || lower == "utilization" || (!lower.contains("percent") && !lower.contains("pct") && value <= 1) {
            return value * 100
        }
        return value
    }

    private static func dictionary(_ value: [String: Any], keys: [String]) -> [String: Any]? {
        keys.lazy.compactMap { value[$0] as? [String: Any] }.first
    }

    private static func number(_ value: [String: Any], keys: [String]) -> (key: String, value: Double)? {
        for key in keys {
            if let number = value[key] as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() {
                return (key, number.doubleValue)
            }
        }
        return nil
    }

    private static func integer(_ value: [String: Any], keys: [String]) -> Int? {
        number(value, keys: keys).map { Int($0.value) }
    }

    private static func string(_ value: [String: Any], keys: [String]) -> String? {
        keys.lazy.compactMap { value[$0] as? String }.first
    }

    private static func date(_ value: [String: Any], keys: [String]) -> Date? {
        for key in keys {
            if let text = value[key] as? String {
                if let date = ISO8601DateFormatter().date(from: text) { return date }
                if let seconds = Double(text) { return epochDate(seconds) }
            }
            if let number = value[key] as? NSNumber { return epochDate(number.doubleValue) }
        }
        return nil
    }

    private static func epochDate(_ value: Double) -> Date {
        Date(timeIntervalSince1970: value > 10_000_000_000 ? value / 1_000 : value)
    }

    private static func displayPlan(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
}
