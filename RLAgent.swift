import Foundation

@MainActor
final class RLAgent {
    var qTable: QTable
    var epsilon: Double
    let epsilonDecay: Double
    let epsilonMin: Double

    private(set) var lastState: String?
    private(set) var lastAction: String?
    private(set) var episodeSteps: Int = 0
    private(set) var totalEpisodes: Int = 0
    private(set) var bestEpisodeSteps: Int = Int.max

    init(
        qTable: QTable = QTable(),
        epsilon: Double = 1.0,
        epsilonDecay: Double = 0.97,
        epsilonMin: Double = 0.1
    ) {
        self.qTable = qTable
        self.epsilon = epsilon
        self.epsilonDecay = epsilonDecay
        self.epsilonMin = epsilonMin
    }

    func chooseAction(state: String, availableActions: [String]) -> String {
        lastState = state
        let action: String
        if Double.random(in: 0...1) < epsilon {
            action = availableActions.randomElement()!
        } else {
            action = qTable.bestAction(for: state, actions: availableActions) ?? availableActions.randomElement()!
        }
        lastAction = action
        episodeSteps += 1
        return action
    }

    func receiveReward(_ reward: Double, nextState: String, availableActions: [String], isTerminal: Bool = false) {
        guard let state = lastState, let action = lastAction else { return }
        qTable.update(
            state: state,
            action: action,
            reward: reward,
            nextState: nextState,
            availableActions: availableActions,
            isTerminal: isTerminal
        )
    }

    func endEpisode() {
        if episodeSteps < bestEpisodeSteps && episodeSteps > 0 {
            bestEpisodeSteps = episodeSteps
        }
        totalEpisodes += 1
        episodeSteps = 0
        epsilon = max(epsilonMin, epsilon * epsilonDecay)
        lastState = nil
        lastAction = nil
    }

    func resetAll() {
        qTable.reset()
        epsilon = 1.0
        episodeSteps = 0
        totalEpisodes = 0
        bestEpisodeSteps = Int.max
        lastState = nil
        lastAction = nil
    }

    /// Resets only the visible counters — called after warm-start so the
    /// HUD shows "Try 1" even though background pre-training already ran.
    func resetVisibleStats() {
        episodeSteps = 0
        totalEpisodes = 0
        bestEpisodeSteps = Int.max
        lastState = nil
        lastAction = nil
    }
}
