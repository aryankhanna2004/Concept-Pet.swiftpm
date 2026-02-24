import Foundation

@MainActor
final class FetchEnvironment: RLEnvironment {
    let gridSize: Int
    private(set) var dogPosition: GridPosition
    private(set) var ballPosition: GridPosition
    private(set) var previousDistance: Int = 0
    private(set) var didBounce: Bool = false

    var currentState: String {
        let dx = ballPosition.x - dogPosition.x
        let dy = ballPosition.y - dogPosition.y
        return "dx:\(dx),dy:\(dy)"
    }

    var availableActions: [String] {
        Direction.allCases.map(\.rawValue)
    }

    var isGoalReached: Bool {
        dogPosition == ballPosition
    }

    var movedCloser: Bool {
        currentDistance < previousDistance
    }

    var currentDistance: Int {
        abs(ballPosition.x - dogPosition.x) + abs(ballPosition.y - dogPosition.y)
    }

    var autoReward: Double {
        if isGoalReached { return 10.0 }
        if didBounce { return -0.8 }
        if movedCloser { return 1.0 }
        if currentDistance > previousDistance { return -0.5 }
        return -0.3
    }

    init(gridSize: Int = 5) {
        self.gridSize = gridSize
        self.dogPosition = GridPosition(
            x: Int.random(in: 0..<gridSize),
            y: Int.random(in: 0..<gridSize)
        )
        var ball: GridPosition
        repeat {
            ball = GridPosition(
                x: Int.random(in: 0..<gridSize),
                y: Int.random(in: 0..<gridSize)
            )
        } while ball == dogPosition
        self.ballPosition = ball
        self.previousDistance = abs(ballPosition.x - dogPosition.x) + abs(ballPosition.y - dogPosition.y)
    }

    func step(action: String) -> String {
        guard let direction = Direction(rawValue: action) else { return currentState }
        previousDistance = currentDistance
        didBounce = false
        let newPos = dogPosition.moved(direction)
        if newPos.x >= 0 && newPos.x < gridSize && newPos.y >= 0 && newPos.y < gridSize {
            dogPosition = newPos
        } else {
            didBounce = true
        }
        return currentState
    }

    func reset() {
        dogPosition = GridPosition(x: Int.random(in: 0..<gridSize), y: Int.random(in: 0..<gridSize))
        repeat {
            ballPosition = GridPosition(x: Int.random(in: 0..<gridSize), y: Int.random(in: 0..<gridSize))
        } while ballPosition == dogPosition
        previousDistance = currentDistance
        didBounce = false
    }
}
