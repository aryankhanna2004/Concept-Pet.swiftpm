import SwiftUI

struct LevelIntroView: View {
    let levelType: LevelType
    @Environment(AppSettings.self) private var settings
    @State private var appeared = false
    @State private var demoStep = 0
    @State private var demoTimer: Timer?
    @State private var heroTick = false
    @State private var heroTimer: Timer?
    @State private var deepDiveExpanded = false

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
                        if settings.enthusiastMode {
                            deepDiveCard
                        }
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

    // MARK: - Deep Dive Card (Enthusiast Mode)

    private var deepDiveCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    deepDiveExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Theme.purple.opacity(0.12))
                            .frame(width: 30, height: 30)
                        Image(systemName: "atom")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.purple)
                    }
                    Text("Deep Dive")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Enthusiast")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.purple)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.purple.opacity(0.12), in: Capsule())
                    Spacer()
                    Image(systemName: deepDiveExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.purple)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if deepDiveExpanded {
                Divider().padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 18) {
                    deepDiveAlgorithm
                    deepDiveFormula
                    deepDiveHyperparams
                    deepDiveLevelSpecific
                }
                .padding(16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Theme.purple.opacity(0.3), lineWidth: 1)
        )
    }

    private var deepDiveAlgorithm: some View {
        VStack(alignment: .leading, spacing: 10) {
            ddSectionHeader("Q-Learning Algorithm", icon: "brain.fill")

            ddText("Q-Learning is how the pup figures out what to do. It keeps a giant cheat sheet called a Q-table. For every situation (state) and every possible move (action), it stores a score: \"how good is this move from here?\" The higher the score, the more the pup trusts that move.")

            ddText("Every single step follows the same loop:")
            VStack(alignment: .leading, spacing: 8) {
                ddNumbered(1, "Look at where you are — the current state s")
                ddNumbered(2, "Decide what to do — using ε-greedy (explained below)")
                ddNumbered(3, "Do it, get a reward r, land in new state s'")
                ddNumbered(4, "Update the cheat sheet — the Bellman equation")
                ddNumbered(5, "Lower ε a little — be slightly less random next time")
            }
        }
    }

    private var deepDiveFormula: some View {
        VStack(alignment: .leading, spacing: 14) {
            ddSectionHeader("Bellman Update Equation", icon: "function")

            // Equation — split into two lines cleanly
            VStack(alignment: .leading, spacing: 2) {
                Text("Q(s, a)  ←  Q(s, a)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.purple)
                Text("  +  α · [ r  +  γ · maxQ(s',a')  −  Q(s,a) ]")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.purple)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.purple.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))

            ddText("Read it as: the new score for this move = the old score, shifted a little bit toward what just happened. Each term has an exact meaning in the math — and a direct real-world meaning in your pup's brain.")

            // Term-by-term: symbol + formal name + plain meaning
            VStack(alignment: .leading, spacing: 12) {
                ddTermRow(
                    symbol: "Q(s, a)",
                    formalName: "Action-value function",
                    color: Theme.purple,
                    plain: "The score on the cheat sheet for taking action a in state s. This number answers: \"how good is it, in the long run, to do this move right now?\" It's what gets updated every step."
                )
                ddTermRow(
                    symbol: "←",
                    formalName: "Assignment (update)",
                    color: Theme.textSecondary,
                    plain: "We're not solving an equation — we're overwriting the old value with a new, slightly better estimate. The left side becomes the result of the right side."
                )
                ddTermRow(
                    symbol: "α  (alpha)",
                    formalName: "Learning rate",
                    color: Theme.blue,
                    plain: "Controls how big a step we take toward the new estimate. α = 0.7 means: take 70% of the correction, keep 30% of the old value. High α = learns fast but can be jumpy. Low α = stable but slow."
                )
                ddTermRow(
                    symbol: "r",
                    formalName: "Reward signal",
                    color: Theme.green,
                    plain: "The immediate reward from this step — the treat or the bad you just gave. This is the only real-world feedback the pup gets. Everything else is the pup's own estimates."
                )
                ddTermRow(
                    symbol: "γ  (gamma)",
                    formalName: "Discount factor",
                    color: Theme.orange,
                    plain: "How much the pup values future rewards vs right now. γ = 0.95 means a treat that's 2 steps away is still worth ~90% of an immediate treat. γ = 0 would mean only care about right now. γ = 1 means infinite patience."
                )
                ddTermRow(
                    symbol: "maxQ(s', a')",
                    formalName: "Maximum future Q-value",
                    color: Theme.teal,
                    plain: "The best score in the cheat sheet for any action from the next state s'. This is the pup's own guess about how good the future looks from here. It's bootstrapping — learning from its own estimates."
                )
                ddTermRow(
                    symbol: "[ r + γ·maxQ − Q(s,a) ]",
                    formalName: "Temporal difference (TD) error",
                    color: Theme.red,
                    plain: "The gap between what the pup expected and what actually happened. Positive = it was pleasantly surprised (score too low). Negative = disappointed (score too high). We correct by α × this gap. If TD error = 0, the prediction was perfect — no update needed."
                )
            }
        }
    }

    private var deepDiveHyperparams: some View {
        VStack(alignment: .leading, spacing: 14) {
            ddSectionHeader("Hyperparameters (this lesson)", icon: "slider.horizontal.3")

            let p = hyperparamInfo

            ddText("These are the knobs set before training starts. Unlike Q-values, they don't change automatically — they shape how learning happens. Each one has a formal role in the algorithm and a practical effect you can observe.")

            VStack(alignment: .leading, spacing: 14) {
                ddHyperparam(
                    symbol: "α = \(String(format: "%.2f", p.alpha))",
                    formalName: "Learning rate  (alpha)",
                    formalRole: "Scales the TD error before updating Q",
                    color: Theme.blue,
                    plain: "At \(String(format: "%.2f", p.alpha)), each update moves the score \(Int(p.alpha * 100))% toward the new target. Too high → the pup keeps second-guessing itself. Too low → takes forever to learn anything."
                )
                ddHyperparam(
                    symbol: "γ = \(String(format: "%.2f", p.gamma))",
                    formalName: "Discount factor  (gamma)",
                    formalRole: "Weights future Q-values in the Bellman equation",
                    color: Theme.orange,
                    plain: "At \(String(format: "%.2f", p.gamma)), a treat 2 steps away is worth \(String(format: "%.0f%%", p.gamma * p.gamma * 100)) of an immediate one. This makes the pup plan ahead rather than just chase the nearest reward."
                )
                ddHyperparam(
                    symbol: "ε₀ = \(String(format: "%.2f", p.epsilonStart))",
                    formalName: "Initial epsilon  (exploration rate)",
                    formalRole: "Starting probability of choosing a random action",
                    color: Theme.purple,
                    plain: "The pup ignores its cheat sheet and picks randomly \(Int(p.epsilonStart * 100))% of the time at first. This is exploration — it needs to try things before it can know what works."
                )
                ddHyperparam(
                    symbol: "×\(String(format: "%.2f", p.epsilonDecay))  per episode",
                    formalName: "Epsilon decay  (annealing schedule)",
                    formalRole: "Multiplies ε after each episode ends",
                    color: Theme.purple.opacity(0.8),
                    plain: "After each round, ε shrinks by \(Int((1 - p.epsilonDecay) * 100))%. This is called annealing — start broad, gradually commit. As the cheat sheet fills in, random exploration becomes less valuable."
                )
                ddHyperparam(
                    symbol: "ε_min = \(String(format: "%.2f", p.epsilonMin))",
                    formalName: "Minimum epsilon  (exploration floor)",
                    formalRole: "Lower bound — ε never goes below this",
                    color: Theme.purple.opacity(0.6),
                    plain: "Even after full training, the pup still acts randomly \(Int(p.epsilonMin * 100))% of the time. This prevents getting permanently stuck in a bad habit if conditions change."
                )
            }

            Divider()

            deepDiveEpsilonGreedy
        }
    }

    private var deepDiveEpsilonGreedy: some View {
        VStack(alignment: .leading, spacing: 10) {
            ddSectionHeader("ε-Greedy Policy", icon: "dice")

            ddText("Formally: a policy π where the agent selects the greedy (highest Q) action with probability 1−ε, and a uniformly random action with probability ε.")
            ddText("In plain terms: it's a weighted coin flip the pup does every single step.")

            // Visual coin flip
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.purple.opacity(0.12))
                    VStack(spacing: 5) {
                        Text("🎲")
                            .font(.system(size: 22))
                        Text("Explore")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.purple)
                        Text("prob = ε")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.purple.opacity(0.8))
                        Text("Pick any random action")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                }
                .frame(maxWidth: .infinity)

                Text("or")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)

                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.green.opacity(0.10))
                    VStack(spacing: 5) {
                        Text("🧠")
                            .font(.system(size: 22))
                        Text("Exploit")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.green)
                        Text("prob = 1−ε")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Theme.green.opacity(0.8))
                        Text("Pick argmax Q(s, a)")
                            .font(.system(size: 10, weight: .regular, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                }
                .frame(maxWidth: .infinity)
            }

            ddText("argmax Q(s, a) — formal term for \"pick the action with the highest Q-value in the current state.\" This is the greedy choice — no randomness, just trust the cheat sheet.")

            ddText("Why not always be greedy? Because early on, most Q-values are 0 — the cheat sheet is blank. Greedy would just lock you into the first thing that got any reward. Exploration forces the agent to visit more of the state space and build a complete map before committing.")

            ddText("Why not always explore? Because you'd never actually use what you learned. The whole point of training is to eventually trust the cheat sheet.")
        }
    }

    private var hyperparamInfo: (alpha: Double, gamma: Double, epsilonStart: Double, epsilonDecay: Double, epsilonMin: Double) {
        switch levelType {
        case .fetch:   return (0.7, 0.95, 0.55, 0.92, 0.02)
        case .sit:     return (0.7, 0.90, 0.50, 0.92, 0.02)
        case .maze:    return (0.6, 0.95, 0.60, 0.94, 0.03)
        case .patrol:  return (0.6, 0.95, 0.60, 0.94, 0.03)
        case .sock:    return (0.7, 0.95, 0.55, 0.92, 0.02)
        }
    }

    private var deepDiveLevelSpecific: some View {
        VStack(alignment: .leading, spacing: 10) {
            ddSectionHeader("Concept: \(levelType.aiConceptTag)", icon: levelType.icon)
            ddText(levelConceptDeepText)
            ddText(levelStateSpaceText)
        }
    }

    private var levelConceptDeepText: String {
        switch levelType {
        case .fetch:
            return "Reward shaping augments the sparse terminal reward by adding intermediate signals. Without shaping, the agent receives reward only at the goal, making credit assignment hard across many steps. By rewarding proximity, the gradient of reward is dense — every step provides learning signal."
        case .sit:
            return "This is a two-action bandit problem at heart: the agent must learn that 'sit' maximises Q over 'move'. Because the state space is tiny (command active + stillness count), convergence is fast and you can directly observe Q-values diverge between the two actions as training proceeds."
        case .maze:
            return "Maze navigation with walls demonstrates the exploration–exploitation tradeoff clearly. High ε means the agent tries random paths — crucial early on. As ε decays, it commits to paths it has found rewarding. Too-fast decay = getting stuck in local optima. Too-slow decay = never exploiting learned knowledge."
        case .patrol:
            return "Patrol requires learning a state-conditional policy: the optimal action in cell X differs depending on which waypoint the agent is heading to next. This requires the full (position × target) state space, making the Q-table significantly larger than simpler lessons."
        case .sock:
            return "Avoidance learning works through negative reinforcement: the sock cell accumulates a deeply negative Q-value. Because γ is high, the agent propagates that penalty backwards — cells adjacent to the sock also become slightly negative, creating a natural 'repulsion field' the agent learns to navigate around."
        }
    }

    private var levelStateSpaceText: String {
        switch levelType {
        case .fetch:   return "State space: 25 grid positions (5×5). Actions: up, down, left, right. Q-table size: 100 entries."
        case .sit:     return "State space: (commandActive, stillnessCount). Actions: sit, move. Q-table size: ~12 entries."
        case .maze:    return "State space: 36 grid positions (6×6) minus walls. Actions: 4 directions. Q-table size: ~144 entries."
        case .patrol:  return "State space: 16 positions × 4 waypoint targets = 64 states. Actions: 4 directions. Q-table size: ~256 entries."
        case .sock:    return "State space: 25 grid positions (5×5). Actions: up, down, left, right. Q-table size: 100 entries — but sock cell Q-values go strongly negative."
        }
    }

    // MARK: - Deep Dive Sub-components

    private func ddSectionHeader(_ title: String, icon: String) -> some View {
        Label {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        } icon: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.purple)
        }
    }

    private func ddText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .regular, design: .rounded))
            .foregroundStyle(Theme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func ddParam(_ name: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(name)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(Theme.purple)
                .frame(minWidth: 100, alignment: .leading)
            Text(value)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func ddTermRow(symbol: String, formalName: String, color: Color, plain: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(symbol)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 5))
                    .fixedSize()
                Text(formalName)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            Text(plain)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)
        }
    }

    private func ddHyperparam(symbol: String, formalName: String, formalRole: String, color: Color, plain: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(symbol)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(color.opacity(0.10), in: Capsule())
                    .fixedSize()
                VStack(alignment: .leading, spacing: 1) {
                    Text(formalName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(formalRole)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(color.opacity(0.8))
                }
            }
            Text(plain)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 4)
        }
    }

    private func ddNumbered(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(n)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Theme.purple.opacity(0.7), in: Circle())
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
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
