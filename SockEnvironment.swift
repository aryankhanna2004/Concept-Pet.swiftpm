import Foundation

@MainActor
final class SockEnvironment: RLEnvironment {
    let gridSize: Int
    private(set) var dogPosition: GridPosition
    private(set) var ballPosition: GridPosition
    private(set) var sockPosition: GridPosition
    private(set) var previousBallDistance: Int = 0
    private(set) var previousSockDistance: Int = 0
    private(set) var didBounce: Bool = false
    private(set) var steppedOnSock: Bool = false

    var ballDistance: Int {
        abs(ballPosition.x - dogPosition.x) + abs(ballPosition.y - dogPosition.y)
    }

    var sockDistance: Int {
        abs(sockPosition.x - dogPosition.x) + abs(sockPosition.y - dogPosition.y)
    }

    var currentState: String {
        let bdx = ballPosition.x - dogPosition.x
        let bdy = ballPosition.y - dogPosition.y
        let sdx = sockPosition.x - dogPosition.x
        let sdy = sockPosition.y - dogPosition.y
        return "bdx:\(bdx),bdy:\(bdy),sdx:\(sdx),sdy:\(sdy)"
    }

    var availableActions: [String] {
        Direction.allCases.map(\.rawValue)
    }

    var isGoalReached: Bool {
        dogPosition == ballPosition
    }

    var autoReward: Double {
        if steppedOnSock { return -5.0 }
        if isGoalReached { return 10.0 }
        if didBounce { return -0.8 }

        var reward = 0.0
        if ballDistance < previousBallDistance {
            reward += 1.0
        } else if ballDistance > previousBallDistance {
            reward -= 0.5
        } else {
            reward -= 0.2
        }

        if sockDistance <= 1 && sockDistance < previousSockDistance {
            reward -= 1.5
        }

        return reward
    }

    init(gridSize: Int = 5) {
        self.gridSize = gridSize
        self.dogPosition = GridPosition(x: 0, y: 0)
        self.ballPosition = GridPosition(x: gridSize - 1, y: gridSize - 1)
        self.sockPosition = GridPosition(x: gridSize / 2, y: gridSize / 2)
        self.previousBallDistance = abs(ballPosition.x) + abs(ballPosition.y)
        self.previousSockDistance = abs(sockPosition.x) + abs(sockPosition.y)
        randomizePlacement()
    }

    func step(action: String) -> String {
        guard let direction = Direction(rawValue: action) else { return currentState }
        previousBallDistance = ballDistance
        previousSockDistance = sockDistance
        didBounce = false
        steppedOnSock = false

        let newPos = dogPosition.moved(direction)
        if newPos.x >= 0 && newPos.x < gridSize && newPos.y >= 0 && newPos.y < gridSize {
            dogPosition = newPos
        } else {
            didBounce = true
        }

        if dogPosition == sockPosition {
            steppedOnSock = true
        }

        return currentState
    }

    func reset() {
        randomizePlacement()
    }

    private func randomizePlacement() {
        var positions = Set<GridPosition>()
        func randomPos() -> GridPosition {
            var p: GridPosition
            repeat {
                p = GridPosition(x: Int.random(in: 0..<gridSize), y: Int.random(in: 0..<gridSize))
            } while positions.contains(p)
            positions.insert(p)
            return p
        }

        dogPosition = randomPos()

        var ball: GridPosition
        repeat {
            ball = GridPosition(x: Int.random(in: 0..<gridSize), y: Int.random(in: 0..<gridSize))
        } while positions.contains(ball) || ball.manhattan(to: dogPosition) < 2
        positions.insert(ball)
        ballPosition = ball

        sockPosition = randomPos()

        previousBallDistance = ballDistance
        previousSockDistance = sockDistance
        didBounce = false
        steppedOnSock = false
    }
}
