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

    // MARK: - Mini Q-Table Demo

    private var miniQTableDemo: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(levelType.accentColor)
                Text("Watch the pup learn")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            miniGrid
                .frame(height: 140)

            HStack(spacing: 16) {
                legendItem(color: Color(red: 0.88, green: 0.94, blue: 0.82), label: "Unknown")
                legendItem(color: Color(red: 0.30, green: 0.78, blue: 0.42), label: "Good move")
                legendItem(color: Color(red: 0.88, green: 0.30, blue: 0.26), label: "Bad move")
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .padding(14)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
    }

    private var miniGrid: some View {
        let size = 3
        return GeometryReader { geo in
            let cellSize = min((geo.size.width - 20) / CGFloat(size), (geo.size.height - 4) / CGFloat(size))
            let gridW = cellSize * CGFloat(size)
            let gridH = cellSize * CGFloat(size)
            let offsetX = (geo.size.width - gridW) / 2
            let offsetY = (geo.size.height - gridH) / 2

            ForEach(0..<size, id: \.self) { row in
                ForEach(0..<size, id: \.self) { col in
                    let idx = row * size + col
                    let cellColor = demoColor(idx: idx, step: demoStep)
                    let arrow = demoArrow(idx: idx, step: demoStep)

                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(cellColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 1)
                            )

                        if !arrow.isEmpty {
                            Text(arrow)
                                .font(.system(size: cellSize * 0.35, weight: .bold))
                                .foregroundStyle(.white.opacity(0.9))
                                .transition(.scale.combined(with: .opacity))
                        }

                        if demoIsPup(idx: idx, step: demoStep) {
                            Text("🐕")
                                .font(.system(size: cellSize * 0.4))
                                .transition(.scale)
                        }
                        if demoisGoal(idx: idx) {
                            Text(levelType == .sock ? "🎾" : levelType == .maze ? "🦴" : "🎾")
                                .font(.system(size: cellSize * 0.35))
                        }
                        if demoIsDanger(idx: idx) {
                            Text("🧦")
                                .font(.system(size: cellSize * 0.35))
                        }
                    }
                    .frame(width: cellSize - 3, height: cellSize - 3)
                    .position(
                        x: offsetX + CGFloat(col) * cellSize + cellSize / 2,
                        y: offsetY + CGFloat(row) * cellSize + cellSize / 2
                    )
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

    // MARK: - Demo Logic

    private let demoGoalIdx = 8
    private var demoDangerIdx: Int? { levelType == .sock ? 4 : nil }

    private func demoIsPup(idx: Int, step: Int) -> Bool {
        let path = [0, 1, 2, 5, 8]
        let pos = min(step, path.count - 1)
        return path[pos] == idx
    }

    private func demoisGoal(idx: Int) -> Bool { idx == demoGoalIdx }
    private func demoIsDanger(idx: Int) -> Bool { idx == demoDangerIdx }

    private func demoColor(idx: Int, step: Int) -> Color {
        if let danger = demoDangerIdx, idx == danger {
            return Color(red: 0.95, green: 0.75, blue: 0.70)
        }
        if idx == demoGoalIdx && step >= 3 {
            return Color(red: 0.30, green: 0.78, blue: 0.42).opacity(0.7)
        }

        let learnedGood: Set<Int> = step >= 1 ? [0] : []
        let learnedOk: Set<Int> = step >= 2 ? [1, 2] : (step >= 1 ? [1] : [])
        let learnedGreat: Set<Int> = step >= 3 ? [5] : []

        if learnedGreat.contains(idx) {
            return Color(red: 0.30, green: 0.78, blue: 0.42).opacity(0.5)
        }
        if learnedGood.contains(idx) {
            return Color(red: 0.55, green: 0.82, blue: 0.55).opacity(0.4)
        }
        if learnedOk.contains(idx) {
            return Color(red: 0.65, green: 0.85, blue: 0.65).opacity(0.3)
        }
        return Color(red: 0.88, green: 0.94, blue: 0.82)
    }

    private func demoArrow(idx: Int, step: Int) -> String {
        guard step >= 2 else { return "" }
        switch idx {
        case 0: return "→"
        case 1: return step >= 3 ? "→" : ""
        case 2: return step >= 3 ? "↓" : ""
        case 5: return step >= 4 ? "↓" : ""
        default: return ""
        }
    }

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
