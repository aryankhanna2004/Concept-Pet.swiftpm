import Foundation

@MainActor
final class SitEnvironment: RLEnvironment {
    private(set) var commandActive: Bool = false
    private(set) var stillnessCount: Int = 0
    private(set) var dogMoved: Bool = false
    let requiredStillness: Int = 3

    var currentState: String {
        "cmd:\(commandActive ? 1 : 0),still:\(stillnessCount)"
    }

    var availableActions: [String] {
        ["move", "stay"]
    }

    var isGoalReached: Bool {
        commandActive && stillnessCount >= requiredStillness
    }

    var autoReward: Double {
        if isGoalReached { return 10.0 }
        if commandActive {
            return dogMoved ? -1.0 : 1.0
        }
        return 0.0
    }

    func issueCommand() {
        commandActive = true
        stillnessCount = 0
    }

    func step(action: String) -> String {
        if action == "stay" {
            dogMoved = false
            if commandActive {
                stillnessCount += 1
            }
        } else {
            dogMoved = true
            stillnessCount = 0
        }
        return currentState
    }

    func reset() {
        commandActive = false
        stillnessCount = 0
        dogMoved = false
    }
}
