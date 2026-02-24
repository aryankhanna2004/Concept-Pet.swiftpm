import SwiftUI

struct BrainMapView: View {
    let levelType: LevelType
    @Environment(GameState.self) private var state

    private let actions = Direction.allCases.map(\.rawValue)

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    Text("Each arrow shows which way the pup would go. Brighter = more confident.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    if levelType == .sit {
                        sitBrainView
                    } else {
                        gridBrainView
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(red: 0, green: 0.3, blue: 1))
                                .frame(width: 12, height: 12)
                            Text("Unsure")
                                .font(Theme.small)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        HStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(red: 1, green: 0.8, blue: 0))
                                .frame(width: 12, height: 12)
                            Text("Confident")
                                .font(Theme.small)
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var gridBrainView: some View {
        let gridSize: Int
        switch levelType {
        case .maze: gridSize = 6
        case .patrol: gridSize = 4
        default: gridSize = 5
        }
        let qt = state.qTable(for: levelType)
        let tiles = computeTiles(gridSize: gridSize, qt: qt)

        return Canvas { context, size in
            let tileW = min((size.width - 20) / CGFloat(gridSize), 52)
            let totalW = tileW * CGFloat(gridSize)
            let originX = (size.width - totalW) / 2
            let originY: CGFloat = 8

            for t in tiles {
                let rect = CGRect(
                    x: originX + CGFloat(t.col) * tileW + 1,
                    y: originY + CGFloat(t.row) * tileW + 1,
                    width: tileW - 2,
                    height: tileW - 2
                )
                context.fill(Path(roundedRect: rect, cornerRadius: 5), with: .color(t.color))

                if let arrow = t.arrow {
                    context.draw(
                        Text(arrow)
                            .font(.system(size: tileW * 0.4, weight: .bold))
                            .foregroundColor(.white.opacity(0.9)),
                        at: CGPoint(x: rect.midX, y: rect.midY)
                    )
                }
            }
        }
        .frame(height: CGFloat(gridSize) * 52 + 16)
    }

    private struct Tile: Sendable {
        let row: Int, col: Int, color: Color, arrow: String?
    }

    private func computeTiles(gridSize: Int, qt: QTable) -> [Tile] {
        var result: [Tile] = []
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if levelType == .maze && state.mazeEnv.walls.contains(GridPosition(x: col, y: row)) {
                    result.append(Tile(row: row, col: col, color: Theme.gridWall, arrow: nil))
                    continue
                }

                let stateStr: String
                switch levelType {
                case .fetch:
                    let dx = state.fetchEnv.ballPosition.x - col
                    let dy = state.fetchEnv.ballPosition.y - row
                    stateStr = "dx:\(dx),dy:\(dy)"
                case .maze:
                    stateStr = state.mazeEnv.stateString(for: GridPosition(x: col, y: row))
                case .patrol:
                    stateStr = "x:\(col),y:\(row),wp:\(state.patrolEnv.waypointIndex)"
                case .sit:
                    continue
                case .sock:
                    let bdx = state.sockEnv.ballPosition.x - col
                    let bdy = state.sockEnv.ballPosition.y - row
                    let sdx = state.sockEnv.sockPosition.x - col
                    let sdy = state.sockEnv.sockPosition.y - row
                    stateStr = "bdx:\(bdx),bdy:\(bdy),sdx:\(sdx),sdy:\(sdy)"
                }

                let maxQ = qt.maxValue(for: stateStr, actions: actions)
                let norm = min(max(maxQ / 5.0, 0), 1.0)
                let color = Color(red: norm, green: norm * 0.8 + 0.3, blue: 1.0 - norm)

                var arrow: String? = nil
                if maxQ > 0.05, let best = qt.bestAction(for: stateStr, actions: actions) {
                    arrow = ["up": "↑", "down": "↓", "left": "←", "right": "→"][best]
                }

                result.append(Tile(row: row, col: col, color: color, arrow: arrow))
            }
        }
        return result
    }

    private var sitBrainView: some View {
        let qt = state.qTable(for: levelType)
        let sitActions = ["move", "stay"]

        return VStack(spacing: 12) {
            ForEach(0..<2, id: \.self) { cmd in
                VStack(alignment: .leading, spacing: 6) {
                    Text(cmd == 0 ? "No command" : "After \"Sit!\"")
                        .font(Theme.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(cmd == 0 ? Theme.textSecondary : Theme.blue)

                    HStack(spacing: 6) {
                        ForEach(0..<4, id: \.self) { still in
                            let s = "cmd:\(cmd),still:\(still)"
                            let vals = qt.allValues(for: s, actions: sitActions)
                            VStack(spacing: 3) {
                                ForEach(sitActions, id: \.self) { a in
                                    let v = vals[a] ?? 0
                                    let norm = min(max(v / 5.0, 0), 1.0)
                                    Text("\(a == "stay" ? "Sit" : "Move")")
                                        .font(.system(size: 9, weight: v >= (vals.values.max() ?? 0) && v > 0 ? .bold : .regular, design: .monospaced))
                                        .padding(3)
                                        .frame(maxWidth: .infinity)
                                        .background(Color(red: norm, green: norm * 0.8 + 0.3, blue: 1.0 - norm).opacity(0.5), in: RoundedRectangle(cornerRadius: 3))
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}
