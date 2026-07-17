public enum MochiThemeID: String, CaseIterable, Equatable, Sendable {
    case mint
    case sky
    case lavender
    case sakura
    case peach
    case butter
    case oatmeal
    case fog

    public init(storedValue: String) {
        self = Self(rawValue: storedValue) ?? .mint
    }

    public var displayName: String {
        switch self {
        case .mint: "薄荷"
        case .sky: "晴空"
        case .lavender: "薰衣草"
        case .sakura: "樱花"
        case .peach: "蜜桃"
        case .butter: "奶油"
        case .oatmeal: "燕麦"
        case .fog: "雾蓝"
        }
    }
}

public enum CatReaction: String, CaseIterable, Equatable, Sendable {
    case hearts
    case stars
    case blush
    case grin
    case tongue

    public var next: CatReaction {
        switch self {
        case .hearts: .stars
        case .stars: .blush
        case .blush: .grin
        case .grin: .tongue
        case .tongue: .hearts
        }
    }

    public var eyes: String {
        switch self {
        case .hearts: "♥  ♥"
        case .stars: "✦  ✦"
        case .blush: "•  •"
        case .grin: "⌒  ⌒"
        case .tongue: ">  <"
        }
    }

    public var mouth: String {
        switch self {
        case .hearts, .blush: "ᴗ"
        case .stars: "ω"
        case .grin: "▽"
        case .tongue: "ڡ"
        }
    }
}

public enum FoodBurstStyle: Equatable, Sendable {
    case still
    case tiny
    case popping
    case sparkling
    case firework

    public init(mood: TokenSpeedMood) {
        switch mood {
        case .learning, .resting: self = .still
        case .nibbling: self = .tiny
        case .munching: self = .popping
        case .gobbling: self = .sparkling
        case .flying: self = .firework
        }
    }

    public var kibbleCount: Int {
        switch self {
        case .still: 0
        case .tiny: 1
        case .popping: 3
        case .sparkling: 5
        case .firework: 8
        }
    }

    public var sparkCount: Int {
        switch self {
        case .still, .tiny, .popping: 0
        case .sparkling: 3
        case .firework: 7
        }
    }

    public var cycleDuration: Double? {
        switch self {
        case .still: nil
        case .tiny: 1.8
        case .popping: 1.25
        case .sparkling: 0.8
        case .firework: 0.48
        }
    }

    public var travelStrength: Double {
        switch self {
        case .still: 0
        case .tiny: 0.45
        case .popping: 0.7
        case .sparkling: 0.95
        case .firework: 1.35
        }
    }
}
