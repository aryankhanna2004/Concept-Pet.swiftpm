import Foundation

@MainActor
final class PatrolEnvironment: RLEnvironment {
    let gridSize: Int
    let waypoints: [GridPosition]
    private(set) var dogPosition: GridPosition
    private(set) var waypointIndex: Int = 0
    private(set) var previousDistance: Int = 0
    private(set) var didBounce: Bool = false
    private(set) var waypointsVisited: Int = 0

    var currentState: String {
        "x:\(dogPosition.x),y:\(dogPosition.y),wp:\(waypointIndex)"
    }

    var availableActions: [String] {
        Direction.allCases.map(\.rawValue)
    }

    var nextWaypoint: GridPosition {
        waypoints[waypointIndex]
    }

    var currentDistance: Int {
        abs(nextWaypoint.x - dogPosition.x) + abs(nextWaypoint.y - dogPosition.y)
    }

    var movedCloser: Bool {
        currentDistance < previousDistance
    }

    var isGoalReached: Bool {
        waypointsVisited >= waypoints.count
    }

    var autoReward: Double {
        if dogPosition == nextWaypoint && !isGoalReached {
            return 10.0
        }
        if isGoalReached { return 10.0 }
        if didBounce { return -0.8 }
        if movedCloser { return 1.0 }
        if currentDistance > previousDistance { return -0.5 }
        return -0.3
    }

    init(gridSize: Int = 4) {
        self.gridSize = gridSize
        self.waypoints = [
            GridPosition(x: gridSize - 1, y: 0),
            GridPosition(x: gridSize - 1, y: gridSize - 1),
            GridPosition(x: 0, y: gridSize - 1),
            GridPosition(x: 0, y: 0)
        ]
        self.dogPosition = GridPosition(x: 0, y: 0)
        self.previousDistance = abs(waypoints[0].x) + abs(waypoints[0].y)
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

        if dogPosition == nextWaypoint && !isGoalReached {
            waypointsVisited += 1
            waypointIndex = waypointsVisited % waypoints.count
            previousDistance = currentDistance
        }

        return currentState
    }

    func reset() {
        dogPosition = GridPosition(x: 0, y: 0)
        waypointIndex = 0
        waypointsVisited = 0
        previousDistance = currentDistance
        didBounce = false
    }
}
