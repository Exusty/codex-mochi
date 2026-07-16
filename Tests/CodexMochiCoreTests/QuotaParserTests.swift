import Foundation
import Testing
@testable import CodexMochiCore

@Test func parsesUsedPercentAsRemainingAcrossPrimaryAndSecondaryWindows() throws {
    let data = Data(#"""
    {
      "plan_type": "plus",
      "rate_limit": {
        "primary_window": {
          "used_percent": 36,
          "reset_at": 1752700000,
          "limit_window_seconds": 18000
        },
        "secondary_window": {
          "used_percent": 74.5,
          "reset_at": "2026-07-20T08:00:00Z",
          "limit_window_seconds": 604800
        }
      }
    }
    """#.utf8)

    let snapshot = try QuotaParser.parse(data: data, now: Date(timeIntervalSince1970: 1_752_600_000))
    let fiveHour = try #require(snapshot.fiveHour)
    let weekly = try #require(snapshot.weekly)

    #expect(snapshot.plan == "Plus")
    #expect(abs(fiveHour.remainingPercent - 64) < 0.001)
    #expect(fiveHour.windowSeconds == 18_000)
    #expect(abs(weekly.remainingPercent - 25.5) < 0.001)
    #expect(weekly.resetsAt == ISO8601DateFormatter().date(from: "2026-07-20T08:00:00Z"))
}

@Test func parsesRatioFieldsAndFindsWindowsArray() throws {
    let data = Data(#"""
    {
      "plan": "team",
      "rateLimit": {
        "windows": [
          { "name": "5h", "remaining_ratio": 0.42, "window_seconds": 18000 },
          { "name": "weekly", "utilization": 0.125, "window_seconds": 604800 }
        ]
      }
    }
    """#.utf8)

    let snapshot = try QuotaParser.parse(data: data)

    #expect(snapshot.plan == "Team")
    #expect(abs((snapshot.fiveHour?.remainingPercent ?? -1) - 42) < 0.001)
    #expect(abs((snapshot.weekly?.remainingPercent ?? -1) - 87.5) < 0.001)
}

@Test func clampsOutOfRangeValues() throws {
    let data = Data(#"""
    {
      "rate_limit": {
        "primary_window": { "remaining_percent": 140, "limit_window_seconds": 18000 },
        "secondary_window": { "used_percent": 250, "limit_window_seconds": 604800 }
      }
    }
    """#.utf8)

    let snapshot = try QuotaParser.parse(data: data)

    #expect(snapshot.fiveHour?.remainingPercent == 100)
    #expect(snapshot.weekly?.remainingPercent == 0)
}

@Test func throwsWhenNoQuotaWindowsCanBeParsed() {
    do {
        _ = try QuotaParser.parse(data: Data(#"{"plan":"plus"}"#.utf8))
        Issue.record("Expected changedResponse")
    } catch {
        #expect(error as? QuotaError == .changedResponse)
    }
}

@Test func quotaLevelsFollowRemainingThresholds() {
    #expect(QuotaLevel(remainingPercent: 75) == .healthy)
    #expect(QuotaLevel(remainingPercent: 50) == .healthy)
    #expect(QuotaLevel(remainingPercent: 49.9) == .caution)
    #expect(QuotaLevel(remainingPercent: 20) == .caution)
    #expect(QuotaLevel(remainingPercent: 19.9) == .critical)
    #expect(QuotaLevel(remainingPercent: 0) == .empty)
}

@Test func extractsChatGPTAccountIDFromJWT() {
    let header = Data(#"{"alg":"none"}"#.utf8).base64URLEncodedString()
    let payload = Data(#"{"https://api.openai.com/auth.chatgpt_account_id":"acct_123"}"#.utf8).base64URLEncodedString()

    #expect(AuthLoader.accountID(fromJWT: "\(header).\(payload).signature") == "acct_123")
    #expect(AuthLoader.accountID(fromJWT: "not-a-jwt") == nil)
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
