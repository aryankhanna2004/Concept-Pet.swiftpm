import Foundation

enum Direction: String, CaseIterable {
    case up, down, left, right
}

struct GridPosition: Equatable, Hashable {
    var x: Int
    var y: Int

    func moved(_ direction: Direction) -> GridPosition {
        switch direction {
        case .up: return GridPosition(x: x, y: y - 1)
        case .down: return GridPosition(x: x, y: y + 1)
        case .left: return GridPosition(x: x - 1, y: y)
        case .right: return GridPosition(x: x + 1, y: y)
        }
    }
}

@MainActor
protocol RLEnvironment: AnyObject {
    var currentState: String { get }
    var availableActions: [String] { get }
    var isGoalReached: Bool { get }
    func step(action: String) -> String
    func reset()
}
