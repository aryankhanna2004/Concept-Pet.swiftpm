import SwiftUI

struct LevelIntroView: View {
    let levelType: LevelType
    @State private var appeared = false
    @State private var demoStep = 0
    @State private var demoTimer: Timer?
    @State private var heroTick = false
    @State private var heroTimer: Timer?

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 32)

                    iconHeader
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    Spacer().frame(height: 20)

                    Text(levelType.title)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 6)

                    Text(levelType.aiConceptTag)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(levelType.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(levelType.accentColor.opacity(0.10), in: Capsule())
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 24)

                    miniQTableDemo
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 6)

                    Spacer().frame(height: 20)

                    VStack(alignment: .leading, spacing: 14) {
                        qLearningCard
                        conceptBulletCard
                        howToPlayCard
                    }
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)

                    Spacer().frame(height: 28)

                    NavigationLink(destination: GameView(levelType: levelType)) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14))
                            Text("Start Lesson")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(levelType.accentColor, in: Capsule())
                    }
                    .padding(.horizontal, 48)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            startDemo()
            startHero()
        }
        .onDisappear {
            demoTimer?.invalidate()
            heroTimer?.invalidate()
        }
    }

    // MARK: - Icon Header

    private var iconHeader: some View {
        ZStack {
            Circle()
                .fill(levelType.accentColor.opacity(0.08))
                .frame(width: 120, height: 120)

            Circle()
                .fill(levelType.accentColor.opacity(0.05))
                .frame(width: 150, height: 150)
                .scaleEffect(appeared ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: appeared)

            heroScene
        }
        .frame(width: 150, height: 150)
    }

    @ViewBuilder
    private var heroScene: some View {
        switch levelType {
        case .fetch:
            FetchHeroView(tick: heroTick, accentColor: levelType.accentColor)
        case .sit:
            SitHeroView(tick: heroTick, accentColor: levelType.accentColor)
        case .maze:
            MazeHeroView(tick: heroTick, accentColor: levelType.accentColor)
        case .patrol:
            PatrolHeroView(tick: heroTick, accentColor: levelType.accentColor)
        case .sock:
            SockHeroView(tick: heroTick, accentColor: levelType.accentColor)
        }
    }

    private func startHero() {
        heroTick = false
        heroTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    heroTick.toggle()
                }
            }
        }
    }

    // MARK: - Mini Demo

    private var miniQTableDemo: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(levelType.accentColor)
                Text(demoTitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            demoContent
                .frame(height: 140)

            demoLegend
                .font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
    }

    private var demoTitle: String {
        switch levelType {
        case .fetch:   return "Reward gets stronger closer to the ball"
        case .sit:     return "Command → action → reward loop"
        case .maze:    return "Exploring unknown paths"
        case .patrol:  return "Visiting waypoints in order"
        case .sock:    return "Learning to avoid danger"
        }
    }

    @ViewBuilder
    private var demoContent: some View {
        switch levelType {
        case .fetch:   fetchDemoGrid
        case .sit:     sitDemoLoop
        case .maze:    mazeDemoGrid
        case .patrol:  patrolDemoRow
        case .sock:    sockDemoGrid
        }
    }

    @ViewBuilder
    private var demoLegend: some View {
        switch levelType {
        case .fetch:
            HStack(spacing: 16) {
                legendItem(color: Color(red: 0.88, green: 0.94, blue: 0.82), label: "Far away")
                legendItem(color: Color(red: 0.30, green: 0.78, blue: 0.42), label: "Getting closer")
            }
        case .sit:
            HStack(spacing: 16) {
                legendItem(color: Color(red: 0.30, green: 0.78, blue: 0.42), label: "Sit score")
                legendItem(color: Color(red: 0.88, green: 0.30, blue: 0.26).opacity(0.75), label: "Move score")
            }
        case .maze:
            HStack(spacing: 16) {
                legendItem(color: Color(red: 0.88, green: 0.94, blue: 0.82), label: "Unknown")
                legendItem(color: Color(red: 0.30, green: 0.78, blue: 0.42), label: "Good path")
                legendItem(color: Color(red: 0.35, green: 0.35, blue: 0.40).opacity(0.5), label: "Wall")
            }
        case .patrol:
            HStack(spacing: 16) {
                legendItem(color: levelType.accentColor.opacity(0.3), label: "Not visited")
                legendItem(color: levelType.accentColor, label: "Reached!")
            }
        case .sock:
            HStack(spacing: 16) {
                legendItem(color: Color(red: 0.88, green: 0.94, blue: 0.82), label: "Unknown")
                legendItem(color: Color(red: 0.30, green: 0.78, blue: 0.42), label: "Safe path")
                legendItem(color: Color(red: 0.88, green: 0.30, blue: 0.26), label: "Danger!")
            }
        }
    }

    // MARK: - Fetch Demo (3×3, reward shaping — cells warm up as pup nears ball)

    // Path: 0→3→6→7→8 — moving down then right toward goal at bottom-right
    private var fetchDemoGrid: some View {
        let size = 3
        // reward-shaped colours: distance from goal (idx 8) drives colour
        let distanceToGoal: [Int: Int] = [0: 4, 1: 3, 2: 2, 3: 3, 4: 2, 5: 1, 6: 2, 7: 1, 8: 0]
        let path = [0, 3, 6, 7, 8]

        return GeometryReader { geo in
            let cellSize = min((geo.size.width - 20) / CGFloat(size), (geo.size.height - 4) / CGFloat(size))
            let gridW = cellSize * CGFloat(size)
            let gridH = cellSize * CGFloat(size)
            let ox = (geo.size.width - gridW) / 2
            let oy = (geo.size.height - gridH) / 2

            ForEach(0..<size, id: \.self) { row in
                ForEach(0..<size, id: \.self) { col in
                    let idx = row * size + col
                    let dist = distanceToGoal[idx] ?? 4
                    let visited = path.prefix(demoStep + 1).contains(idx)
                    let isGoal = idx == 8
                    let isPup = path[min(demoStep, path.count - 1)] == idx

                    let cellColor: Color = isGoal
                        ? Color(red: 0.30, green: 0.78, blue: 0.42).opacity(0.75)
                        : visited
                            ? Color(red: 0.30 + Double(dist) * 0.12, green: 0.78 - Double(dist) * 0.06, blue: 0.30).opacity(0.35 + Double(4 - dist) * 0.08)
                            : Color(red: 0.88, green: 0.94, blue: 0.82)

                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(cellColor)
                            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
                        if isGoal { Text("🎾").font(.system(size: cellSize * 0.35)) }
                        if isPup  { Text("🐕").font(.system(size: cellSize * 0.40)).transition(.scale) }
                    }
                    .frame(width: cellSize - 3, height: cellSize - 3)
                    .position(x: ox + CGFloat(col) * cellSize + cellSize / 2,
                              y: oy + CGFloat(row) * cellSize + cellSize / 2)
                    .animation(.easeInOut(duration: 0.4), value: demoStep)
                }
            }
        }
    }

    // MARK: - Sit Demo (command → action → reward loop, no grid)

    private var sitDemoLoop: some View {
        // Q-values evolve: early on both are unknown, over time Sit score climbs
        let sitScores:  [CGFloat] = [0.1, 0.25, 0.55, 0.80, 0.92]
        let moveScores: [CGFloat] = [0.1, 0.20, 0.18, 0.12, 0.08]
        let sitScore  = sitScores[min(demoStep, sitScores.count - 1)]
        let moveScore = moveScores[min(demoStep, moveScores.count - 1)]
        let isTrained = demoStep >= 3

        return VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 16) {
                sitScoreBar(
                    label: "Sit 🐶",
                    score: sitScore,
                    color: isTrained ? Color(red: 0.30, green: 0.78, blue: 0.42) : levelType.accentColor,
                    highlight: isTrained
                )
                sitScoreBar(
                    label: "Move 🐕",
                    score: moveScore,
                    color: Color(red: 0.88, green: 0.30, blue: 0.26).opacity(0.75),
                    highlight: false
                )
            }
            .frame(height: 88)
            .animation(.easeInOut(duration: 0.5), value: demoStep)

            Text(isTrained ? "Pup learned: Sit = best move! 🦴" : "Learning which action scores higher…")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(isTrained ? Color(red: 0.30, green: 0.78, blue: 0.42) : Theme.textSecondary)
                .animation(.easeInOut(duration: 0.4), value: demoStep)
        }
        .padding(.horizontal, 8)
    }

    private func sitScoreBar(label: String, score: CGFloat, color: Color, highlight: Bool) -> some View {
        VStack(spacing: 6) {
            Text(String(format: "%.0f%%", score * 100))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            GeometryReader { geo in
                VStack(spacing: 0) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 6)
                        .fill(color.opacity(0.85))
                        .frame(height: geo.size.height * score)
                        .overlay(
                            highlight
                                ? RoundedRectangle(cornerRadius: 6).strokeBorder(color, lineWidth: 1.5)
                                : nil
                        )
                }
            }

            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Maze Demo (4×4 with wall cells and winding path)

    // Walls at indices: 1, 5, 9, 11; goal at 15; path: 0→4→8→12→13→14→15
    private let mazeWalls: Set<Int> = [1, 5, 9, 11]
    private let mazeGoal = 15
    private let mazePath = [0, 4, 8, 12, 13, 14, 15]

    private var mazeDemoGrid: some View {
        let size = 4
        return GeometryReader { geo in
            let cellSize = min((geo.size.width - 20) / CGFloat(size), (geo.size.height - 4) / CGFloat(size))
            let gridW = cellSize * CGFloat(size)
            let gridH = cellSize * CGFloat(size)
            let ox = (geo.size.width - gridW) / 2
            let oy = (geo.size.height - gridH) / 2

            ForEach(0..<size, id: \.self) { row in
                ForEach(0..<size, id: \.self) { col in
                    let idx = row * size + col
                    let isWall  = mazeWalls.contains(idx)
                    let isGoal  = idx == mazeGoal
                    let visited = mazePath.prefix(demoStep + 1).contains(idx)
                    let isPup   = mazePath[min(demoStep, mazePath.count - 1)] == idx

                    let cellColor: Color = isWall
                        ? Color(red: 0.35, green: 0.35, blue: 0.40).opacity(0.45)
                        : isGoal
                            ? Color(red: 0.30, green: 0.78, blue: 0.42).opacity(0.75)
                            : visited
                                ? Color(red: 0.30, green: 0.78, blue: 0.42).opacity(0.28)
                                : Color(red: 0.88, green: 0.94, blue: 0.82)

                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(cellColor)
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
                        if isWall  { Text("🚧").font(.system(size: cellSize * 0.30)) }
                        if isGoal  { Text("🦴").font(.system(size: cellSize * 0.32)) }
                        if isPup   { Text("🐕").font(.system(size: cellSize * 0.38)).transition(.scale) }
                    }
                    .frame(width: cellSize - 3, height: cellSize - 3)
                    .position(x: ox + CGFloat(col) * cellSize + cellSize / 2,
                              y: oy + CGFloat(row) * cellSize + cellSize / 2)
                    .animation(.easeInOut(duration: 0.4), value: demoStep)
                }
            }
        }
    }

    // MARK: - Patrol Demo (linear waypoints A→B→C→D)

    private var patrolDemoRow: some View {
        let labels = ["A", "B", "C", "D"]
        let reached = demoStep  // 0 = none, 1 = A, 2 = B, 3 = C, 4 = D
        let circleSize: CGFloat = 38

        return GeometryReader { geo in
            let usableWidth = geo.size.width - 16  // matches .padding(.horizontal, 8)
            let spacing = (usableWidth - circleSize * 4) / 3
            let circleX: (Int) -> CGFloat = { i in
                8 + circleSize / 2 + CGFloat(i) * (circleSize + spacing)
            }
            let waypointY: CGFloat = geo.size.height * 0.35
            let dogY: CGFloat = waypointY + circleSize / 2 + 18

            // Connector lines
            ForEach(0..<3, id: \.self) { i in
                let x1 = circleX(i) + circleSize / 2
                let x2 = circleX(i + 1) - circleSize / 2
                Rectangle()
                    .fill(i < reached ? levelType.accentColor : levelType.accentColor.opacity(0.2))
                    .frame(width: x2 - x1, height: 2)
                    .position(x: (x1 + x2) / 2, y: waypointY)
                    .animation(.easeInOut(duration: 0.4), value: demoStep)
            }

            // Waypoint circles
            ForEach(0..<4, id: \.self) { i in
                let done   = i < reached
                let active = i == min(reached, 3)

                ZStack {
                    Circle()
                        .fill(done ? levelType.accentColor : levelType.accentColor.opacity(0.18))
                        .frame(width: circleSize, height: circleSize)
                        .overlay(Circle().strokeBorder(levelType.accentColor.opacity(0.5), lineWidth: 1.5))
                        .scaleEffect(active ? 1.12 : 1.0)

                    Text(done ? "✓" : labels[i])
                        .font(.system(size: done ? 16 : 14, weight: .bold, design: .rounded))
                        .foregroundStyle(done ? .white : levelType.accentColor)
                }
                .position(x: circleX(i), y: waypointY)
                .animation(.easeInOut(duration: 0.4), value: demoStep)
            }

            // Dog exactly below the active waypoint
            Text("🐕")
                .font(.system(size: 28))
                .position(x: circleX(min(reached, 3)), y: dogY)
                .animation(.easeInOut(duration: 0.5), value: demoStep)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sock Demo (3×3, dog routes around danger cell)

    // Danger at idx 4 (centre); goal at 8; safe detour path: 0→1→2→5→8
    private var sockDemoGrid: some View {
        let size = 3
        let dangerIdx = 4
        let goalIdx = 8
        let safePath = [0, 1, 2, 5, 8]

        return GeometryReader { geo in
            let cellSize = min((geo.size.width - 20) / CGFloat(size), (geo.size.height - 4) / CGFloat(size))
            let gridW = cellSize * CGFloat(size)
            let gridH = cellSize * CGFloat(size)
            let ox = (geo.size.width - gridW) / 2
            let oy = (geo.size.height - gridH) / 2

            ForEach(0..<size, id: \.self) { row in
                ForEach(0..<size, id: \.self) { col in
                    let idx = row * size + col
                    let isDanger = idx == dangerIdx
                    let isGoal   = idx == goalIdx
                    let visited  = safePath.prefix(demoStep + 1).contains(idx)
                    let isPup    = safePath[min(demoStep, safePath.count - 1)] == idx

                    let cellColor: Color = isDanger
                        ? Color(red: 0.88, green: 0.30, blue: 0.26).opacity(0.55)
                        : isGoal
                            ? Color(red: 0.30, green: 0.78, blue: 0.42).opacity(0.75)
                            : visited
                                ? Color(red: 0.30, green: 0.78, blue: 0.42).opacity(0.28)
                                : Color(red: 0.88, green: 0.94, blue: 0.82)

                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(cellColor)
                            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.black.opacity(0.06), lineWidth: 1))
                        if isDanger { Text("🧦").font(.system(size: cellSize * 0.35)) }
                        if isGoal   { Text("🎾").font(.system(size: cellSize * 0.35)) }
                        if isPup    { Text("🐕").font(.system(size: cellSize * 0.40)).transition(.scale) }
                    }
                    .frame(width: cellSize - 3, height: cellSize - 3)
                    .position(x: ox + CGFloat(col) * cellSize + cellSize / 2,
                              y: oy + CGFloat(row) * cellSize + cellSize / 2)
                    .animation(.easeInOut(duration: 0.4), value: demoStep)
                }
            }
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Demo Timer

    private func startDemo() {
        demoStep = 0
        demoTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.4)) {
                    demoStep = (demoStep + 1) % 5
                }
            }
        }
    }

    // MARK: - Q-Learning Card

    private var qLearningCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("How your pup thinks")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            } icon: {
                Image(systemName: "brain")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(levelType.accentColor)
            }
            .foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                bulletRow(emoji: "🧠", text: "The pup has a brain, like a big cheat sheet of moves")
                bulletRow(emoji: "📍", text: "For every spot on the grid, it remembers: \"which direction worked best?\"")
                bulletRow(emoji: "🦴", text: "You give a treat → that move gets a higher score")
                bulletRow(emoji: "👎", text: "You say bad → that move gets a lower score")
                bulletRow(emoji: "🎯", text: "Over time, the pup just follows the highest scores")
            }

            Text("That's Q-Learning! Trial, error, and treats.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(levelType.accentColor)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Concept Bullet Card

    private var conceptBulletCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(conceptTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            } icon: {
                Image(systemName: conceptIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(levelType.accentColor)
            }
            .foregroundStyle(Theme.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(conceptBullets, id: \.self) { bullet in
                    bulletRow(emoji: conceptEmoji, text: bullet)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private var conceptTitle: String {
        switch levelType {
        case .fetch: return "Reward Shaping"
        case .sit: return "Reinforcement"
        case .maze: return "Explore vs Exploit"
        case .patrol: return "Policy Learning"
        case .sock: return "Avoidance Learning"
        }
    }

    private var conceptIcon: String {
        switch levelType {
        case .fetch: return "target"
        case .sit: return "hand.thumbsup"
        case .maze: return "questionmark.diamond"
        case .patrol: return "point.topleft.down.to.point.bottomright.curvepath"
        case .sock: return "exclamationmark.triangle"
        }
    }

    private var conceptEmoji: String {
        switch levelType {
        case .fetch: return "💡"
        case .sit: return "✋"
        case .maze: return "🔍"
        case .patrol: return "🗺️"
        case .sock: return "⚠️"
        }
    }

    private var conceptBullets: [String] {
        switch levelType {
        case .fetch: return [
            "Don't just reward at the finish line",
            "Give small treats for getting closer each step",
            "This way the pup gets feedback constantly",
            "Faster learning = happier pup!"
        ]
        case .sit: return [
            "The pup picks an action: sit or move",
            "You tell it good or bad",
            "It remembers which action got the treat",
            "Next time, it picks the winning action more often"
        ]
        case .maze: return [
            "Should the pup try a brand new path?",
            "Or stick with one that worked before?",
            "Early on → explore everything!",
            "Later → use what it learned"
        ]
        case .patrol: return [
            "The pup must visit A → B → C in order",
            "The best move depends on where it is AND where it's going",
            "It can't just learn one trick",
            "It needs a full plan for every spot"
        ]
        case .sock: return [
            "Goal: reach the ball 🎾",
            "Danger: the stinky sock 🧦 is a trap!",
            "Stepping on the sock = big penalty",
            "The pup learns to go around it, not through it"
        ]
        }
    }

    // MARK: - How To Play Card

    private var howToPlayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text("How to play")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            } icon: {
                Image(systemName: "gamecontroller")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(levelType.accentColor)
            }
            .foregroundStyle(Theme.textPrimary)

            ForEach(Array(playSteps.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(levelType.accentColor, in: Circle())

                    Text(step)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private var playSteps: [String] {
        switch levelType {
        case .fetch: return [
            "Tap Step, the pup picks a direction",
            "See if it moved closer to the ball",
            "Tap Treat (good) or Bad (wrong way)"
        ]
        case .sit: return [
            "Tap Sit to give the command",
            "Tap Step to see what the pup does",
            "Stayed still? Treat! Moved? Bad!"
        ]
        case .maze: return [
            "Pup needs to reach the bone 🦴",
            "Reward moves toward the goal",
            "Punish wrong turns and wall hits"
        ]
        case .patrol: return [
            "Pup must visit checkpoints in order",
            "Reward moves toward the next one",
            "It has to learn the entire route!"
        ]
        case .sock: return [
            "Pup must reach the 🎾 ball",
            "Avoid the 🧦 stinky sock!",
            "Sock = big penalty, ball = big reward"
        ]
        }
    }

    // MARK: - Bullet Row Helper

    private func bulletRow(emoji: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(emoji)
                .font(.system(size: 15))
                .frame(width: 22, alignment: .center)
            Text(text)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Hero Scene Views

private struct FetchHeroView: View {
    let tick: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            Text("🎾")
                .font(.system(size: 30))
                .offset(x: tick ? 18 : 22, y: -18)
                .animation(.easeInOut(duration: 0.5), value: tick)

            Text("🐕")
                .font(.system(size: 36))
                .offset(x: tick ? 4 : -10, y: 10)
                .scaleEffect(x: 1, y: 1)
                .animation(.easeInOut(duration: 0.5), value: tick)

            Text("💨")
                .font(.system(size: 16))
                .offset(x: tick ? -14 : -20, y: 14)
                .opacity(tick ? 0.8 : 0.3)
                .animation(.easeInOut(duration: 0.5), value: tick)
        }
    }
}

private struct SitHeroView: View {
    let tick: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            Text("✋")
                .font(.system(size: 28))
                .offset(x: -20, y: -14)
                .scaleEffect(tick ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 0.5), value: tick)

            Text(tick ? "🐶" : "🐕")
                .font(.system(size: 36))
                .offset(x: 12, y: 10)
                .animation(.easeInOut(duration: 0.5), value: tick)

            Text(tick ? "⭐️" : "")
                .font(.system(size: 18))
                .offset(x: 20, y: -18)
                .opacity(tick ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: tick)
        }
    }
}

private struct MazeHeroView: View {
    let tick: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            Text("🦴")
                .font(.system(size: 24))
                .offset(x: 24, y: -20)
                .scaleEffect(tick ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 0.5), value: tick)

            Text("🐕")
                .font(.system(size: 32))
                .offset(x: tick ? 4 : -8, y: tick ? 4 : -4)
                .animation(.easeInOut(duration: 0.5), value: tick)

            Text("?")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .offset(x: tick ? -22 : -16, y: -18)
                .opacity(tick ? 0.3 : 0.9)
                .animation(.easeInOut(duration: 0.5), value: tick)
        }
    }
}

private struct PatrolHeroView: View {
    let tick: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(accentColor.opacity(0.5))
                    .frame(width: 10, height: 10)
                    .offset(x: CGFloat(i - 1) * 24, y: -22)
            }

            Path { path in
                path.move(to: CGPoint(x: -24, y: -17))
                path.addLine(to: CGPoint(x: 0, y: -17))
                path.addLine(to: CGPoint(x: 24, y: -17))
            }
            .stroke(accentColor.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            .frame(width: 80, height: 10)
            .offset(y: -14)

            Text("🐕")
                .font(.system(size: 32))
                .offset(x: tick ? 0 : -24, y: 8)
                .animation(.easeInOut(duration: 0.5), value: tick)
        }
    }
}

private struct SockHeroView: View {
    let tick: Bool
    let accentColor: Color

    var body: some View {
        ZStack {
            Text("🎾")
                .font(.system(size: 26))
                .offset(x: 24, y: -18)

            Text("🧦")
                .font(.system(size: 22))
                .offset(x: 0, y: 12)
                .scaleEffect(tick ? 1.1 : 0.9)
                .animation(.easeInOut(duration: 0.5), value: tick)

            Text("🐕")
                .font(.system(size: 32))
                .offset(x: tick ? -18 : -26, y: -8)
                .animation(.easeInOut(duration: 0.5), value: tick)

            Text("⚠️")
                .font(.system(size: 14))
                .offset(x: 4, y: 28)
                .opacity(tick ? 0.9 : 0.4)
                .animation(.easeInOut(duration: 0.5), value: tick)
        }
    }
}
