import Foundation

public enum StatusTitleFormatter {
    public static func title(snapshot: QuotaSnapshot?, error: QuotaError?) -> String {
        if let percent = snapshot?.fiveHour?.remainingPercent ?? snapshot?.weekly?.remainingPercent {
            return "\(Int(percent.rounded()))%"
        }
        return error == nil ? "…" : "!"
    }
}
