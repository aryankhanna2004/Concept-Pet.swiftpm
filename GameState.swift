import SwiftUI

enum LevelType: Int, CaseIterable, Codable, Identifiable, Sendable {
    case fetch = 0
    case sit = 1
    case maze = 2
    case patrol = 3
    case sock = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .fetch: return "Ball Fetch"
        case .sit: return "Sit Command"
        case .maze: return "Maze Runner"
        case .patrol: return "Patrol Route"
        case .sock: return "Stinky Sock"
        }
    }

    var description: String {
        switch self {
        case .fetch: return "Teach your pup to fetch the ball!"
        case .sit: return "Can your dog learn to sit on command?"
        case .maze: return "Navigate through the maze to find the bone!"
        case .patrol: return "Learn a patrol route around waypoints!"
        case .sock: return "Get the ball but avoid the stinky sock!"
        }
    }

    var icon: String {
        switch self {
        case .fetch: return "tennisball.fill"
        case .sit: return "hand.raised.fill"
        case .maze: return "map.fill"
        case .patrol: return "point.topleft.down.to.point.bottomright.curvepath"
        case .sock: return "exclamationmark.triangle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .fetch: return Theme.green
        case .sit: return Theme.blue
        case .maze: return Theme.orange
        case .patrol: return Theme.teal
        case .sock: return Theme.red
        }
    }

    var aiConceptTag: String {
        switch self {
        case .fetch: return "Reward Shaping"
        case .sit: return "Reinforcement"
        case .maze: return "Exploration"
        case .patrol: return "Policy Learning"
        case .sock: return "Avoidance Learning"
        }
    }

    var aiConceptExplainer: String {
        switch self {
        case .fetch:
            return "Reward shaping means giving small rewards for getting closer to the goal, not just at the end."
        case .sit:
            return "Reinforcement learning means the AI learns which actions are good or bad from your feedback."
        case .maze:
            return "Exploration vs exploitation: try new paths or stick with what works?"
        case .patrol:
            return "The right move depends on where the pup is AND where it needs to go next. The AI must learn a complete plan."
        case .sock:
            return "The pup must learn to chase the ball while avoiding danger. Negative rewards teach it what to stay away from."
        }
    }
}

@MainActor
@Observable
final class GameState {
    var unlockedLevels: Set<LevelType> = Set(LevelType.allCases)
    var currentLevel: LevelType = .fetch
    var treatCount: Int = 0
    var noCount: Int = 0

    private(set) var fetchAgent: RLAgent
    private(set) var sitAgent: RLAgent
    private(set) var mazeAgent: RLAgent
    private(set) var patrolAgent: RLAgent
    private(set) var sockAgent: RLAgent

    let fetchEnv = FetchEnvironment(gridSize: 5)
    let sitEnv = SitEnvironment()
    let mazeEnv = MazeEnvironment(gridSize: 6)
    let patrolEnv = PatrolEnvironment(gridSize: 4)
    let sockEnv = SockEnvironment(gridSize: 5)

    var bestScores: [LevelType: Int] = [:]

    init() {
        fetchAgent = RLAgent(qTable: QTable(alpha: 0.7, gamma: 0.95), epsilon: 0.55, epsilonDecay: 0.92, epsilonMin: 0.02)
        sitAgent = RLAgent(qTable: QTable(alpha: 0.7, gamma: 0.9), epsilon: 0.50, epsilonDecay: 0.92, epsilonMin: 0.02)
        mazeAgent = RLAgent(qTable: QTable(alpha: 0.6, gamma: 0.95), epsilon: 0.60, epsilonDecay: 0.94, epsilonMin: 0.03)
        patrolAgent = RLAgent(qTable: QTable(alpha: 0.6, gamma: 0.95), epsilon: 0.60, epsilonDecay: 0.94, epsilonMin: 0.03)
        sockAgent = RLAgent(qTable: QTable(alpha: 0.7, gamma: 0.95), epsilon: 0.55, epsilonDecay: 0.92, epsilonMin: 0.02)
        load()
        warmStartIfNeeded()
    }

    func agent(for level: LevelType) -> RLAgent {
        switch level {
        case .fetch: return fetchAgent
        case .sit: return sitAgent
        case .maze: return mazeAgent
        case .patrol: return patrolAgent
        case .sock: return sockAgent
        }
    }

    func environment(for level: LevelType) -> any RLEnvironment {
        switch level {
        case .fetch: return fetchEnv
        case .sit: return sitEnv
        case .maze: return mazeEnv
        case .patrol: return patrolEnv
        case .sock: return sockEnv
        }
    }

    func qTable(for level: LevelType) -> QTable {
        agent(for: level).qTable
    }

    func unlockNextLevel(after level: LevelType) {
        save()
    }

    func resetLevel(_ level: LevelType) {
        agent(for: level).resetAll()
        environment(for: level).reset()
        warmStart(level: level)
        save()
    }

    func hardResetAll() {
        // Delete save file
        try? FileManager.default.removeItem(at: saveURL)

        // Rebuild all agents from scratch
        fetchAgent  = RLAgent(qTable: QTable(alpha: 0.7, gamma: 0.95),  epsilon: 1.0, epsilonDecay: 0.92, epsilonMin: 0.02)
        sitAgent    = RLAgent(qTable: QTable(alpha: 0.7, gamma: 0.90),  epsilon: 1.0, epsilonDecay: 0.92, epsilonMin: 0.02)
        mazeAgent   = RLAgent(qTable: QTable(alpha: 0.6, gamma: 0.95),  epsilon: 1.0, epsilonDecay: 0.94, epsilonMin: 0.03)
        patrolAgent = RLAgent(qTable: QTable(alpha: 0.6, gamma: 0.95),  epsilon: 1.0, epsilonDecay: 0.94, epsilonMin: 0.03)
        sockAgent   = RLAgent(qTable: QTable(alpha: 0.7, gamma: 0.95),  epsilon: 1.0, epsilonDecay: 0.92, epsilonMin: 0.02)

        // Reset all environments
        fetchEnv.reset()
        sitEnv.reset()
        mazeEnv.reset()
        patrolEnv.reset()
        sockEnv.reset()

        // Clear stats
        treatCount = 0
        noCount = 0
        bestScores = [:]
        unlockedLevels = Set(LevelType.allCases)

        // Run the same 42-episode warm start so the pup always has a usable baseline
        for level in LevelType.allCases {
            warmStart(level: level)
        }
        save()
    }

    // MARK: - Warm Start Pretraining

    private func warmStartIfNeeded() {
        var changed = false
        for level in LevelType.allCases {
            if agent(for: level).qTable.table.isEmpty {
                warmStart(level: level)
                changed = true
            }
        }
        if changed {
            save()
        }
    }

    private func warmStart(level: LevelType) {
        // 42 episodes seeds the Q-table with enough signal to be responsive
        // without making the HUD look like the user already trained heavily.
        let episodes = 42

        let agent = agent(for: level)
        let env = environment(for: level)

        for _ in 0..<episodes {
            env.reset()
            if let sit = env as? SitEnvironment, !sit.commandActive {
                sit.issueCommand()
            }

            for _ in 0..<30 {
                if let sit = env as? SitEnvironment, !sit.commandActive {
                    sit.issueCommand()
                }

                let state = env.currentState
                let action = agent.chooseAction(state: state, availableActions: env.availableActions)
                let nextState = env.step(action: action)

                var reward = autoReward(for: level)
                let terminal = env.isGoalReached
                if terminal {
                    reward += 8.0
                }

                agent.receiveReward(
                    reward,
                    nextState: nextState,
                    availableActions: env.availableActions,
                    isTerminal: terminal
                )

                if terminal { break }
            }

            agent.endEpisode()
        }

        // Leave enough exploration for user-guided fine-tuning after warm start.
        switch level {
        case .fetch:   agent.epsilon = 0.28
        case .sit:     agent.epsilon = 0.26
        case .maze:    agent.epsilon = 0.32
        case .patrol:  agent.epsilon = 0.34
        case .sock:    agent.epsilon = 0.30
        }

        // Reset visible counters so the HUD reads "Try 1" on first open —
        // warm-up is background prep, not user training.
        agent.resetVisibleStats()

        // Leave env in a clean ready state
        env.reset()
        if let sit = env as? SitEnvironment {
            sit.issueCommand()
        }
    }

    private func autoReward(for level: LevelType) -> Double {
        switch level {
        case .fetch: return fetchEnv.autoReward
        case .sit: return sitEnv.autoReward
        case .maze: return mazeEnv.autoReward
        case .patrol: return patrolEnv.autoReward
        case .sock: return sockEnv.autoReward
        }
    }

    // MARK: - Persistence

    private var saveURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("concept_pet_state.json")
    }

    func save() {
        let data = SaveData(
            unlockedLevels: Array(unlockedLevels),
            treatCount: treatCount,
            noCount: noCount,
            fetchQTable: fetchAgent.qTable,
            sitQTable: sitAgent.qTable,
            mazeQTable: mazeAgent.qTable,
            patrolQTable: patrolAgent.qTable,
            sockQTable: sockAgent.qTable,
            fetchEpsilon: fetchAgent.epsilon,
            sitEpsilon: sitAgent.epsilon,
            mazeEpsilon: mazeAgent.epsilon,
            patrolEpsilon: patrolAgent.epsilon,
            sockEpsilon: sockAgent.epsilon,
            bestScores: bestScores
        )
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: saveURL)
        } catch {
            print("Save failed: \(error)")
        }
    }

    func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let saved = try? JSONDecoder().decode(SaveData.self, from: data) else { return }
        unlockedLevels = Set(LevelType.allCases)
        treatCount = saved.treatCount
        noCount = saved.noCount
        bestScores = saved.bestScores

        fetchAgent = RLAgent(
            qTable: saved.fetchQTable,
            epsilon: min(saved.fetchEpsilon ?? 0.55, 0.55),
            epsilonDecay: 0.92,
            epsilonMin: 0.02
        )
        sitAgent = RLAgent(
            qTable: saved.sitQTable,
            epsilon: min(saved.sitEpsilon ?? 0.50, 0.50),
            epsilonDecay: 0.92,
            epsilonMin: 0.02
        )
        mazeAgent = RLAgent(
            qTable: saved.mazeQTable,
            epsilon: min(saved.mazeEpsilon ?? 0.60, 0.60),
            epsilonDecay: 0.94,
            epsilonMin: 0.03
        )
        if let pq = saved.patrolQTable {
            patrolAgent = RLAgent(
                qTable: pq,
                epsilon: min(saved.patrolEpsilon ?? 0.60, 0.60),
                epsilonDecay: 0.94,
                epsilonMin: 0.03
            )
        }
        if let sq = saved.sockQTable {
            sockAgent = RLAgent(
                qTable: sq,
                epsilon: min(saved.sockEpsilon ?? 0.55, 0.55),
                epsilonDecay: 0.92,
                epsilonMin: 0.02
            )
        }
    }
}

private struct SaveData: Codable, Sendable {
    let unlockedLevels: [LevelType]
    let treatCount: Int
    let noCount: Int
    let fetchQTable: QTable
    let sitQTable: QTable
    let mazeQTable: QTable
    let patrolQTable: QTable?
    let sockQTable: QTable?
    let fetchEpsilon: Double?
    let sitEpsilon: Double?
    let mazeEpsilon: Double?
    let patrolEpsilon: Double?
    let sockEpsilon: Double?
    let bestScores: [LevelType: Int]
}
