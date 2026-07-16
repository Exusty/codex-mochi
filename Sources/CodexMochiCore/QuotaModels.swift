import Foundation

public enum QuotaError: Error, Equatable, Sendable {
    case signedOut
    case invalidAuth
    case unauthorized
    case rateLimited
    case unavailable
    case responseTooLarge
    case changedResponse
    case transport
}

extension QuotaError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .signedOut: "还没找到 Codex 登录，请先打开 Codex 登录。"
        case .invalidAuth: "Codex 登录信息已失效，请重新登录。"
        case .unauthorized: "Codex 登录已过期，请重新登录。"
        case .rateLimited: "额度服务有点忙，稍后会自动重试。"
        case .unavailable: "暂时拿不到额度，保留上次结果。"
        case .responseTooLarge: "额度响应异常，已停止读取。"
        case .changedResponse: "额度格式发生变化，暂时无法显示。"
        case .transport: "网络没有接通，稍后会自动重试。"
        }
    }
}

public struct QuotaWindow: Equatable, Sendable {
    public let remainingPercent: Double
    public let resetsAt: Date?
    public let windowSeconds: Int

    public init(remainingPercent: Double, resetsAt: Date?, windowSeconds: Int) {
        self.remainingPercent = min(100, max(0, remainingPercent))
        self.resetsAt = resetsAt
        self.windowSeconds = windowSeconds
    }
}

public struct QuotaSnapshot: Equatable, Sendable {
    public let plan: String?
    public let fiveHour: QuotaWindow?
    public let weekly: QuotaWindow?
    public let fetchedAt: Date

    public init(plan: String?, fiveHour: QuotaWindow?, weekly: QuotaWindow?, fetchedAt: Date) {
        self.plan = plan
        self.fiveHour = fiveHour
        self.weekly = weekly
        self.fetchedAt = fetchedAt
    }
}

public enum QuotaLevel: Equatable, Sendable {
    case healthy
    case caution
    case critical
    case empty

    public init(remainingPercent: Double) {
        if remainingPercent <= 0 {
            self = .empty
        } else if remainingPercent < 20 {
            self = .critical
        } else if remainingPercent < 50 {
            self = .caution
        } else {
            self = .healthy
        }
    }
}
