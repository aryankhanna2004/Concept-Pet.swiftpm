import Foundation
import Observation

@MainActor
@Observable
final class AppSettings {
    var enthusiastMode: Bool {
        didSet { UserDefaults.standard.set(enthusiastMode, forKey: "enthusiastMode") }
    }

    // Per-level treat reward (positive)
    var treatReward: [LevelType: Double] {
        didSet { saveRewards() }
    }

    // Per-level penalty reward (stored as positive magnitude, applied negative)
    var penaltyReward: [LevelType: Double] {
        didSet { saveRewards() }
    }

    static let defaultTreat: Double  = 1.0
    static let defaultPenalty: Double = 1.0

    init() {
        enthusiastMode = UserDefaults.standard.bool(forKey: "enthusiastMode")

        var treats: [LevelType: Double] = [:]
        var penalties: [LevelType: Double] = [:]
        for level in LevelType.allCases {
            let tk = "treat_\(level.rawValue)"
            let pk = "penalty_\(level.rawValue)"
            treats[level] = UserDefaults.standard.object(forKey: tk) != nil
                ? UserDefaults.standard.double(forKey: tk)
                : AppSettings.defaultTreat
            penalties[level] = UserDefaults.standard.object(forKey: pk) != nil
                ? UserDefaults.standard.double(forKey: pk)
                : AppSettings.defaultPenalty
        }
        treatReward = treats
        penaltyReward = penalties
    }

    func treat(for level: LevelType) -> Double {
        treatReward[level] ?? AppSettings.defaultTreat
    }

    func penalty(for level: LevelType) -> Double {
        penaltyReward[level] ?? AppSettings.defaultPenalty
    }

    func resetRewards() {
        for level in LevelType.allCases {
            treatReward[level] = AppSettings.defaultTreat
            penaltyReward[level] = AppSettings.defaultPenalty
        }
    }

    private func saveRewards() {
        for level in LevelType.allCases {
            UserDefaults.standard.set(treatReward[level], forKey: "treat_\(level.rawValue)")
            UserDefaults.standard.set(penaltyReward[level], forKey: "penalty_\(level.rawValue)")
        }
    }
}
