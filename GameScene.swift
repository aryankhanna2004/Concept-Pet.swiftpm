import SpriteKit

@MainActor
final class GameScene: SKScene {
    var levelType: LevelType = .fetch
    var gameState: GameState?
    var onGoalReached: ((Int) -> Void)?

    private var pet: PetNode!
    private var tileNodes: [[SKShapeNode]] = []
    private var heatmapNodes: [[SKShapeNode]] = []
    private var arrowNodes: [[SKLabelNode]] = []
    private var ballNode: SKShapeNode?
    private var goalNode: SKShapeNode?

    private var gridSize: Int = 5
    private var tileSize: CGFloat = 60
    private var gridOrigin: CGPoint = .zero

    private(set) var waitingForReward = false
    private(set) var pendingNextState: String?
    private(set) var pendingAutoReward: Double = 0.0
    private(set) var isAnimating = false
    private(set) var roundCompleted = false

    private let maxEpisodeSteps = 30
    private var recentPositions: [String] = []

    var showHeatmap = false {
        didSet { updateHeatmapVisibility() }
    }

    override func didMove(to view: SKView) {
        backgroundColor = Theme.sceneBgLight
        setupGrid()
        setupPet()
        setupItems()
    }

    func configure(level: LevelType, state: GameState) {
        self.levelType = level
        self.gameState = state
        switch level {
        case .maze: self.gridSize = 6
        case .patrol: self.gridSize = 4
        default: self.gridSize = 5
        }
    }

    // MARK: - Setup

    private func setupGrid() {
        tileNodes.removeAll()
        heatmapNodes.removeAll()
        arrowNodes.removeAll()
        children.filter { $0.name == "tile" || $0.name == "heatmap" || $0.name == "arrow" }.forEach { $0.removeFromParent() }

        let sceneW = size.width
        let sceneH = size.height
        let maxTile = min((sceneW - 40) / CGFloat(gridSize), (sceneH - 100) / CGFloat(gridSize))
        tileSize = min(maxTile, 65)
        let gridW = tileSize * CGFloat(gridSize)
        let gridH = tileSize * CGFloat(gridSize)
        gridOrigin = CGPoint(x: (sceneW - gridW) / 2, y: (sceneH - gridH) / 2 + 10)

        for row in 0..<gridSize {
            var tileRow: [SKShapeNode] = []
            var heatRow: [SKShapeNode] = []
            var arrowRow: [SKLabelNode] = []
            for col in 0..<gridSize {
                let pos = tilePosition(col: col, row: row)

                let tile = SKShapeNode(rectOf: CGSize(width: tileSize - 2, height: tileSize - 2), cornerRadius: 6)
                tile.name = "tile"
                tile.position = pos

                let isWall = levelType == .maze && (gameState?.mazeEnv.walls.contains(GridPosition(x: col, y: row)) ?? false)
                tile.fillColor = isWall ? Theme.sceneWallLight : Theme.sceneFloorLight
                tile.strokeColor = SKColor(white: 0, alpha: 0.15)
                tile.lineWidth = 1.5
                addChild(tile)
                tileRow.append(tile)

                let heat = SKShapeNode(rectOf: CGSize(width: tileSize - 2, height: tileSize - 2), cornerRadius: 6)
                heat.name = "heatmap"
                heat.position = pos
                heat.fillColor = .clear
                heat.strokeColor = .clear
                heat.alpha = 0.5
                heat.zPosition = 1
                heat.isHidden = !showHeatmap
                addChild(heat)
                heatRow.append(heat)

                let arrow = SKLabelNode(text: "")
                arrow.name = "arrow"
                arrow.position = pos
                arrow.fontSize = tileSize * 0.35
                arrow.fontName = "AvenirNext-Bold"
                arrow.fontColor = .white
                arrow.verticalAlignmentMode = .center
                arrow.horizontalAlignmentMode = .center
                arrow.zPosition = 2
                arrow.isHidden = !showHeatmap
                addChild(arrow)
                arrowRow.append(arrow)
            }
            tileNodes.append(tileRow)
            heatmapNodes.append(heatRow)
            arrowNodes.append(arrowRow)
        }
    }

    private func setupPet() {
        pet?.removeFromParent()
        pet = PetNode(size: tileSize * 0.75)
        pet.zPosition = 10
        addChild(pet)
        updatePetPosition(animated: false)
    }

    private func setupItems() {
        ballNode?.removeFromParent()
        goalNode?.removeFromParent()
        children.filter { $0.name == "goalItem" }.forEach { $0.removeFromParent() }

        if levelType == .fetch, let env = gameState?.fetchEnv {
            let ball = SKLabelNode(text: "🎾")
            ball.fontSize = tileSize * 0.5
            ball.verticalAlignmentMode = .center
            ball.horizontalAlignmentMode = .center
            ball.zPosition = 5
            ball.name = "goalItem"
            ball.position = tilePosition(col: env.ballPosition.x, row: env.ballPosition.y)
            addChild(ball)
        }

        if levelType == .maze, let env = gameState?.mazeEnv {
            let bone = SKLabelNode(text: "🦴")
            bone.fontSize = tileSize * 0.45
            bone.verticalAlignmentMode = .center
            bone.position = tilePosition(col: env.goal.x, row: env.goal.y)
            bone.zPosition = 5
            bone.name = "goalItem"
            addChild(bone)
        }

        if levelType == .patrol, let env = gameState?.patrolEnv {
            for (i, wp) in env.waypoints.enumerated() {
                let marker = SKShapeNode(circleOfRadius: tileSize * 0.18)
                marker.zPosition = 4
                marker.name = "goalItem"
                marker.position = tilePosition(col: wp.x, row: wp.y)
                marker.lineWidth = 2

                if i == env.waypointIndex {
                    marker.fillColor = SKColor(red: 0.2, green: 0.85, blue: 0.75, alpha: 0.8)
                    marker.strokeColor = SKColor(red: 0.1, green: 0.6, blue: 0.55, alpha: 1)
                    let pulse = SKAction.sequence([
                        .scale(to: 1.2, duration: 0.4),
                        .scale(to: 1.0, duration: 0.4)
                    ])
                    marker.run(.repeatForever(pulse))
                } else {
                    marker.fillColor = SKColor(red: 0.2, green: 0.85, blue: 0.75, alpha: 0.25)
                    marker.strokeColor = SKColor(red: 0.1, green: 0.6, blue: 0.55, alpha: 0.5)
                }

                let label = SKLabelNode(text: "\(i + 1)")
                label.fontSize = tileSize * 0.22
                label.fontName = "AvenirNext-Bold"
                label.verticalAlignmentMode = .center
                label.horizontalAlignmentMode = .center
                label.fontColor = .white
                marker.addChild(label)

                addChild(marker)
            }
        }

        if levelType == .sock, let env = gameState?.sockEnv {
            let ball = SKLabelNode(text: "🎾")
            ball.fontSize = tileSize * 0.5
            ball.verticalAlignmentMode = .center
            ball.horizontalAlignmentMode = .center
            ball.zPosition = 5
            ball.name = "goalItem"
            ball.position = tilePosition(col: env.ballPosition.x, row: env.ballPosition.y)
            addChild(ball)

            let sock = SKLabelNode(text: "🧦")
            sock.fontSize = tileSize * 0.5
            sock.verticalAlignmentMode = .center
            sock.horizontalAlignmentMode = .center
            sock.zPosition = 5
            sock.name = "goalItem"
            sock.position = tilePosition(col: env.sockPosition.x, row: env.sockPosition.y)
            addChild(sock)

            let stink = SKLabelNode(text: "💨")
            stink.fontSize = tileSize * 0.25
            stink.verticalAlignmentMode = .center
            stink.horizontalAlignmentMode = .center
            stink.zPosition = 6
            stink.name = "goalItem"
            stink.position = CGPoint(
                x: tilePosition(col: env.sockPosition.x, row: env.sockPosition.y).x + tileSize * 0.2,
                y: tilePosition(col: env.sockPosition.x, row: env.sockPosition.y).y + tileSize * 0.2
            )
            let drift = SKAction.sequence([
                .moveBy(x: 3, y: 4, duration: 0.8),
                .moveBy(x: -3, y: -4, duration: 0.8)
            ])
            stink.run(.repeatForever(drift))
            addChild(stink)
        }
    }

    // MARK: - Step

    func performStep() {
        guard !waitingForReward, !isAnimating, !roundCompleted, let state = gameState else { return }
        let agent = state.agent(for: levelType)
        let env = state.environment(for: levelType)

        if agent.episodeSteps >= maxEpisodeSteps {
            resetEpisode()
            return
        }

        let currentState = env.currentState
        let action = agent.chooseAction(state: currentState, availableActions: env.availableActions)
        let nextState = env.step(action: action)

        pendingNextState = nextState
        pendingAutoReward = computeAutoReward(nextState: nextState)
        waitingForReward = true

        animatePetMove(action: action) {
            self.isAnimating = false
            if action != "stay" {
                self.pet.setState(.idle)
            }
        }
    }

    private func computeAutoReward(nextState: String) -> Double {
        guard let state = gameState else { return 0 }
        var reward: Double
        switch levelType {
        case .fetch: reward = state.fetchEnv.autoReward
        case .sit: reward = state.sitEnv.autoReward
        case .maze: reward = state.mazeEnv.autoReward
        case .patrol: reward = state.patrolEnv.autoReward
        case .sock: reward = state.sockEnv.autoReward
        }

        recentPositions.append(nextState)
        if recentPositions.count > 3 { recentPositions.removeFirst() }
        if recentPositions.count >= 3 {
            let last3 = Set(recentPositions)
            if last3.count <= 2 {
                reward -= 0.5
            }
        }

        return reward
    }

    func deliverReward(_ userReward: Double) {
        guard waitingForReward, let state = gameState, let nextState = pendingNextState else { return }
        let agent = state.agent(for: levelType)
        let env = state.environment(for: levelType)
        let goalReached = env.isGoalReached

        let shapedReward = pendingAutoReward
        var trainingReward = userReward
        if userReward > 0, shapedReward > 0 {
            trainingReward += 0.2 * shapedReward
        } else if userReward < 0, shapedReward < 0 {
            trainingReward += 0.2 * shapedReward
        }
        if goalReached {
            trainingReward += 8.0
        }
        agent.receiveReward(trainingReward, nextState: nextState, availableActions: env.availableActions, isTerminal: goalReached)

        let hasReaction: Bool
        if userReward > 0 {
            state.treatCount += 1
            pet.setState(.happy)
            showTreatParticle()
            hasReaction = true
        } else if userReward < 0 {
            state.noCount += 1
            pet.setState(.sad)
            hasReaction = true
        } else {
            hasReaction = false
        }

        finishReward(env: env, keepReaction: hasReaction)
    }

    func deliverAutoReward() {
        guard waitingForReward, let state = gameState, let nextState = pendingNextState else { return }
        let agent = state.agent(for: levelType)
        let env = state.environment(for: levelType)
        let goalReached = env.isGoalReached

        agent.receiveReward(pendingAutoReward, nextState: nextState, availableActions: env.availableActions, isTerminal: goalReached)

        if pendingAutoReward > 0.1 {
            state.treatCount += 1
        } else if pendingAutoReward < -0.1 {
            state.noCount += 1
        }

        finishReward(env: env)
    }

    private func finishReward(env: any RLEnvironment, keepReaction: Bool = false) {
        let goalReached = env.isGoalReached

        waitingForReward = false
        pendingNextState = nil

        if !keepReaction {
            pet.setState(.idle)
        }
        updateHeatmap()

        if goalReached {
            handleGoalReached()
        }
    }

    func resetEpisode() {
        guard let state = gameState else { return }
        let agent = state.agent(for: levelType)
        let env = state.environment(for: levelType)

        if agent.lastState != nil {
            agent.endEpisode()
        }
        env.reset()
        waitingForReward = false
        pendingNextState = nil
        isAnimating = false
        roundCompleted = false
        recentPositions.removeAll()

        setupItems()
        updatePetPosition(animated: false)
        updateHeatmap()
        state.save()
    }

    // MARK: - Animation

    private func animatePetMove(action: String, completion: @escaping () -> Void) {
        isAnimating = true

        if let dir = Direction(rawValue: action) {
            switch dir {
            case .up: pet.setState(.walkUp)
            case .down: pet.setState(.walkDown)
            case .left: pet.setState(.walkLeft)
            case .right: pet.setState(.walkRight)
            }
        } else if action == "stay" {
            pet.setState(.sit)
        } else if action == "move" {
            pet.setState(.walkRight)
        }

        updatePetPosition(animated: true, completion: completion)
    }

    private func updatePetPosition(animated: Bool, completion: (() -> Void)? = nil) {
        let pos: CGPoint
        switch levelType {
        case .fetch:
            if let env = gameState?.fetchEnv {
                pos = tilePosition(col: env.dogPosition.x, row: env.dogPosition.y)
            } else { pos = .zero }
        case .sit:
            pos = tilePosition(col: gridSize / 2, row: gridSize / 2)
        case .maze:
            if let env = gameState?.mazeEnv {
                pos = tilePosition(col: env.dogPosition.x, row: env.dogPosition.y)
            } else { pos = .zero }
        case .patrol:
            if let env = gameState?.patrolEnv {
                pos = tilePosition(col: env.dogPosition.x, row: env.dogPosition.y)
            } else { pos = .zero }
        case .sock:
            if let env = gameState?.sockEnv {
                pos = tilePosition(col: env.dogPosition.x, row: env.dogPosition.y)
            } else { pos = .zero }
        }

        if animated {
            pet.run(.move(to: pos, duration: 0.18)) {
                completion?()
            }
        } else {
            pet.position = pos
            completion?()
        }
    }

    private func showTreatParticle() {
        let treat = SKLabelNode(text: "🦴")
        treat.fontSize = tileSize * 0.35
        treat.position = CGPoint(x: pet.position.x + tileSize * 0.3, y: pet.position.y - tileSize * 0.15)
        treat.zPosition = 20
        treat.alpha = 0
        addChild(treat)

        let appear = SKAction.fadeIn(withDuration: 0.15)
        let drop = SKAction.moveBy(x: -tileSize * 0.15, y: -tileSize * 0.1, duration: 0.2)
        let wait = SKAction.wait(forDuration: 0.6)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        treat.run(.sequence([appear, drop, wait, fade])) {
            treat.removeFromParent()
        }
    }

    private func handleGoalReached() {
        guard let state = gameState else { return }
        let agent = state.agent(for: levelType)
        let steps = agent.episodeSteps

        if state.bestScores[levelType] == nil || steps < (state.bestScores[levelType] ?? Int.max) {
            state.bestScores[levelType] = steps
        }

        state.unlockNextLevel(after: levelType)
        roundCompleted = true
        if let callback = onGoalReached {
            callback(steps)
        } else {
            resetEpisode()
        }
    }

    // MARK: - Heatmap

    func updateHeatmap() {
        guard showHeatmap, let state = gameState else { return }
        let qt = state.qTable(for: levelType)
        let actions = Direction.allCases.map(\.rawValue)
        let arrowMap = ["up": "↑", "down": "↓", "left": "←", "right": "→"]

        for row in 0..<gridSize {
            for col in 0..<heatmapNodes[row].count {
                let stateStr: String
                switch levelType {
                case .fetch:
                    if let env = gameState?.fetchEnv {
                        let dx = env.ballPosition.x - col
                        let dy = env.ballPosition.y - row
                        stateStr = "dx:\(dx),dy:\(dy)"
                    } else { continue }
                case .maze:
                    if let env = gameState?.mazeEnv {
                        stateStr = env.stateString(for: GridPosition(x: col, y: row))
                    } else { continue }
                case .patrol:
                    if let env = gameState?.patrolEnv {
                        stateStr = "x:\(col),y:\(row),wp:\(env.waypointIndex)"
                    } else { continue }
                case .sit:
                    continue
                case .sock:
                    if let env = gameState?.sockEnv {
                        let bdx = env.ballPosition.x - col
                        let bdy = env.ballPosition.y - row
                        let sdx = env.sockPosition.x - col
                        let sdy = env.sockPosition.y - row
                        stateStr = "bdx:\(bdx),bdy:\(bdy),sdx:\(sdx),sdy:\(sdy)"
                    } else { continue }
                }

                let maxQ = qt.maxValue(for: stateStr, actions: actions)
                let norm = min(max(maxQ / 5.0, 0), 1.0)

                let r: CGFloat = 0.18 + norm * 0.12
                let g: CGFloat = 0.55 + norm * 0.30
                let b: CGFloat = 0.34 + norm * 0.08
                heatmapNodes[row][col].fillColor = SKColor(red: r, green: g, blue: b, alpha: 0.55)

                if maxQ > 0.05, let best = qt.bestAction(for: stateStr, actions: actions) {
                    arrowNodes[row][col].text = arrowMap[best] ?? ""
                    arrowNodes[row][col].fontColor = SKColor(white: 1, alpha: min(0.4 + norm * 0.6, 1.0))
                } else {
                    arrowNodes[row][col].text = ""
                }
            }
        }
    }

    private func updateHeatmapVisibility() {
        for row in 0..<heatmapNodes.count {
            for col in 0..<heatmapNodes[row].count {
                heatmapNodes[row][col].isHidden = !showHeatmap
                if row < arrowNodes.count && col < arrowNodes[row].count {
                    arrowNodes[row][col].isHidden = !showHeatmap
                }
            }
        }
        if showHeatmap { updateHeatmap() }
    }

    // MARK: - Helpers

    private func tilePosition(col: Int, row: Int) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + CGFloat(col) * tileSize + tileSize / 2,
            y: gridOrigin.y + CGFloat(gridSize - 1 - row) * tileSize + tileSize / 2
        )
    }
}
