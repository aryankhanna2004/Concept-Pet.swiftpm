import Foundation

struct StateAction: Hashable, Codable, Sendable {
    let state: String
    let action: String
}

struct QTable: Codable, Sendable {
    var table: [StateAction: Double] = [:]
    var alpha: Double = 0.3
    var gamma: Double = 0.9

    init(alpha: Double = 0.3, gamma: Double = 0.9) {
        self.alpha = alpha
        self.gamma = gamma
    }

    func getValue(state: String, action: String) -> Double {
        table[StateAction(state: state, action: action)] ?? 0.0
    }

    func bestAction(for state: String, actions: [String]) -> String? {
        guard !actions.isEmpty else { return nil }
        var bestValue = Double.leastNonzeroMagnitude * -1
        var candidates: [String] = []
        for action in actions {
            let q = getValue(state: state, action: action)
            if q > bestValue + 1e-9 {
                bestValue = q
                candidates = [action]
            } else if abs(q - bestValue) <= 1e-9 {
                candidates.append(action)
            }
        }
        return candidates.randomElement()
    }

    mutating func update(state: String, action: String, reward: Double, nextState: String, availableActions: [String], isTerminal: Bool = false) {
        let currentQ = getValue(state: state, action: action)
        let maxNextQ = isTerminal ? 0.0 : (availableActions.map { getValue(state: nextState, action: $0) }.max() ?? 0.0)
        let newQ = currentQ + alpha * (reward + gamma * maxNextQ - currentQ)
        table[StateAction(state: state, action: action)] = newQ
    }

    func allValues(for state: String, actions: [String]) -> [String: Double] {
        var result: [String: Double] = [:]
        for a in actions {
            result[a] = getValue(state: state, action: a)
        }
        return result
    }

    func maxValue(for state: String, actions: [String]) -> Double {
        actions.map { getValue(state: state, action: $0) }.max() ?? 0.0
    }

    mutating func reset() {
        table.removeAll()
    }
}
