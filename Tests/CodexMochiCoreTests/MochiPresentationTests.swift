import Testing
@testable import CodexMochiCore

@Test func mochiThemesExposeEightStableChoicesAndSafeFallback() {
    #expect(MochiThemeID.allCases.map(\.rawValue) == [
        "mint", "sky", "lavender", "sakura", "peach", "butter", "oatmeal", "fog",
    ])
    #expect(MochiThemeID(storedValue: "lavender") == .lavender)
    #expect(MochiThemeID(storedValue: "future-theme") == .mint)
}

@Test func mochiThemesExposeDistinctAccentColorsForThemeDrivenCards() {
    let accents = MochiThemeID.allCases.map(\.accent)

    #expect(Set(accents).count == MochiThemeID.allCases.count)
    #expect(MochiThemeID.mint.accent == MochiThemeAccent(red: 0.45, green: 0.84, blue: 0.69))
    #expect(MochiThemeID.sky.accent == MochiThemeAccent(red: 0.46, green: 0.74, blue: 0.92))
    #expect(MochiThemeID.fog.accent == MochiThemeAccent(red: 0.66, green: 0.71, blue: 0.77))
}

@Test func catReactionsCycleWithoutRepeatingTheCurrentFace() {
    #expect(CatReaction.hearts.next == .stars)
    #expect(CatReaction.stars.next == .blush)
    #expect(CatReaction.blush.next == .grin)
    #expect(CatReaction.grin.next == .tongue)
    #expect(CatReaction.tongue.next == .hearts)
}

@Test func foodBurstStyleEscalatesFromQuietKibbleToStraightFlyingSparks() {
    #expect(FoodBurstStyle(mood: .learning) == .still)
    #expect(FoodBurstStyle(mood: .resting) == .still)
    #expect(FoodBurstStyle(mood: .nibbling) == .tiny)
    #expect(FoodBurstStyle(mood: .munching) == .popping)
    #expect(FoodBurstStyle(mood: .gobbling) == .sparkling)
    #expect(FoodBurstStyle(mood: .flying) == .firework)

    #expect(FoodBurstStyle.tiny.kibbleCount == 1)
    #expect(FoodBurstStyle.popping.kibbleCount == 3)
    #expect(FoodBurstStyle.sparkling.kibbleCount == 5)
    #expect(FoodBurstStyle.firework.kibbleCount == 8)
    #expect(FoodBurstStyle.sparkling.sparkCount == 3)
    #expect(FoodBurstStyle.firework.sparkCount == 7)
    #expect(FoodBurstStyle.firework.travelStrength > FoodBurstStyle.sparkling.travelStrength)
    #expect(FoodBurstStyle.firework.cycleDuration == 0.48)
}
