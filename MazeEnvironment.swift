import Foundation

@MainActor
final class MazeEnvironment: RLEnvironment {
    let gridSize: Int
    let walls: Set<GridPosition>
    let goal: GridPosition
    private(set) var dogPosition: GridPosition
    private(set) var previousDistance: Int = 0
    private(set) var hitWall: Bool = false

    var currentState: String {
        stateString(for: dogPosition)
    }

    var availableActions: [String] {
        Direction.allCases.map(\.rawValue)
    }

    var isGoalReached: Bool {
        dogPosition == goal
    }

    var currentDistance: Int {
        abs(goal.x - dogPosition.x) + abs(goal.y - dogPosition.y)
    }

    var movedCloser: Bool {
        currentDistance < previousDistance
    }

    var autoReward: Double {
        if isGoalReached { return 10.0 }
        if hitWall { return -1.0 }
        if movedCloser { return 1.0 }
        if currentDistance > previousDistance { return -0.5 }
        return -0.3
    }

    init(gridSize: Int = 6) {
        self.gridSize = gridSize
        self.goal = GridPosition(x: gridSize - 1, y: gridSize - 1)
        self.dogPosition = GridPosition(x: 0, y: 0)

        var w = Set<GridPosition>()
        w.insert(GridPosition(x: 1, y: 0))
        w.insert(GridPosition(x: 1, y: 1))
        w.insert(GridPosition(x: 1, y: 2))
        w.insert(GridPosition(x: 3, y: 2))
        w.insert(GridPosition(x: 3, y: 3))
        w.insert(GridPosition(x: 3, y: 4))
        w.insert(GridPosition(x: 4, y: 1))
        w.insert(GridPosition(x: 2, y: 4))
        self.walls = w
        self.previousDistance = abs(goal.x) + abs(goal.y)
    }

    func step(action: String) -> String {
        guard let direction = Direction(rawValue: action) else { return currentState }
        previousDistance = currentDistance
        hitWall = false
        let newPos = dogPosition.moved(direction)
        if newPos.x >= 0 && newPos.x < gridSize && newPos.y >= 0 && newPos.y < gridSize && !walls.contains(newPos) {
            dogPosition = newPos
        } else {
            hitWall = true
        }
        return currentState
    }

    func stateString(for position: GridPosition) -> String {
        let dx = goal.x - position.x
        let dy = goal.y - position.y

        let upBlocked = isBlocked(position.moved(.up)) ? 1 : 0
        let downBlocked = isBlocked(position.moved(.down)) ? 1 : 0
        let leftBlocked = isBlocked(position.moved(.left)) ? 1 : 0
        let rightBlocked = isBlocked(position.moved(.right)) ? 1 : 0

        // Goal-relative state with local obstacle awareness reduces overfitting to absolute cells.
        return "dx:\(dx),dy:\(dy),u:\(upBlocked),d:\(downBlocked),l:\(leftBlocked),r:\(rightBlocked)"
    }

    private func isBlocked(_ p: GridPosition) -> Bool {
        p.x < 0 || p.x >= gridSize || p.y < 0 || p.y >= gridSize || walls.contains(p)
    }

    func reset() {
        dogPosition = GridPosition(x: 0, y: 0)
        previousDistance = currentDistance
        hitWall = false
    }
}
