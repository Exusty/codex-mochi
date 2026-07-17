import Testing
@testable import CodexMochiCore

@Test func detectsMembershipWithoutGuessingGenericPro() {
    #expect(MembershipTier.detect(plan: "Plus") == .plus)
    #expect(MembershipTier.detect(plan: "pro") == .pro)
    #expect(MembershipTier.detect(plan: "pro-5x") == .pro5x)
    #expect(MembershipTier.detect(plan: "PRO 20X") == .pro20x)
    #expect(MembershipTier.detect(plan: "pro_20x") == .pro20x)
    #expect(MembershipTier.detect(plan: nil) == .member)
    #expect(MembershipTier.detect(plan: "Team") == .member)
}

@Test func manualMembershipOverrideWinsUntilAutomaticIsRestored() {
    #expect(MembershipTier.resolved(detected: .pro, override: .automatic) == .pro)
    #expect(MembershipTier.resolved(detected: .pro, override: .pro20x) == .pro20x)
    #expect(MembershipTier.resolved(detected: .plus, override: .pro5x) == .pro5x)
    #expect(MembershipTier.resolved(detected: .member, override: .plus) == .plus)
}

@Test func membershipOverridesUseStablePersistedValues() {
    #expect(MembershipOverride(rawValue: "automatic") == .automatic)
    #expect(MembershipOverride(rawValue: "pro5x") == .pro5x)
    #expect(MembershipOverride(rawValue: "pro20x") == .pro20x)
}
