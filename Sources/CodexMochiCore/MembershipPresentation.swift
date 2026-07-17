public enum MembershipTier: Equatable, Sendable {
    case plus
    case pro
    case pro5x
    case pro20x
    case member

    public static func detect(plan: String?) -> MembershipTier {
        guard let plan else { return .member }
        let normalized = plan.lowercased().filter { $0.isLetter || $0.isNumber }
        if normalized.contains("pro20x") { return .pro20x }
        if normalized.contains("pro5x") { return .pro5x }
        if normalized == "pro" { return .pro }
        if normalized.contains("plus") { return .plus }
        return .member
    }

    public static func resolved(
        detected: MembershipTier,
        override: MembershipOverride
    ) -> MembershipTier {
        switch override {
        case .automatic: detected
        case .plus: .plus
        case .pro5x: .pro5x
        case .pro20x: .pro20x
        }
    }
}

public enum MembershipOverride: String, CaseIterable, Equatable, Sendable {
    case automatic
    case plus
    case pro5x
    case pro20x
}
