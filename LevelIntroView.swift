import SwiftUI

struct LevelIntroView: View {
    let levelType: LevelType
    @State private var appeared = false
    @State private var demoStep = 0
    @State private var demoTimer: Timer?
    @State private var showConceptDetail = false

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
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(levelType.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(levelType.accentColor.opacity(0.10), in: Capsule())
                        .opacity(appeared ? 1 : 0)

                    Spacer().frame(height: 24)

                    miniQTableDemo
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 6)

                    Spacer().frame(height: 20)

                    VStack(alignment: .leading, spacing: 14) {
                        conceptCard(
                            title: "What is Q-Learning?",
                            body: "Your pup has a brain (a table of values). Each cell says \"how good is it to go left, right, up, or down from here?\" Every time you give a treat or say bad, those values update. Over time the pup learns the best move for every spot.",
                            icon: "brain"
                        )

                        conceptCard(
                            title: conceptTitle,
                            body: conceptBody,
                            icon: conceptIcon
                        )

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
        }
        .onDisappear { demoTimer?.invalidate() }
    }

    // MARK: - Icon Header

    private var iconHeader: some View {
        ZStack {
            Circle()
                .fill(levelType.accentColor.opacity(0.08))
                .frame(width: 100, height: 100)

            Circle()
                .fill(levelType.accentColor.opacity(0.05))
                .frame(width: 130, height: 130)
                .scaleEffect(appeared ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: appeared)

            Image(systemName: levelType.icon)
                .font(.system(size: 40))
                .foregroundStyle(levelType.accentColor)
        }
    }

    // MARK: - Mini Q-Table Demo

    private var miniQTableDemo: some View {
        VStack(spacing: 10) {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(levelType.accentColor)
                Text("Watch the pup learn")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }

            miniGrid
                .frame(height: 140)

            HStack(spacing: 16) {
                legendItem(color: Color(red: 0.88, green: 0.94, blue: 0.82), label: "Unknown")
                legendItem(color: Color(red: 0.30, green: 0.78, blue: 0.42), label: "Good move")
                legendItem(color: Color(red: 0.88, green: 0.30, blue: 0.26), label: "Bad move")
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
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

    // MARK: - Concept content per level

    private var conceptTitle: String {
        switch levelType {
        case .fetch: return "Reward Shaping"
        case .sit: return "Reinforcement"
        case .maze: return "Exploration vs Exploitation"
        case .patrol: return "Policy Learning"
        case .sock: return "Avoidance Learning"
        }
    }

    private var conceptBody: String {
        switch levelType {
        case .fetch:
            return "Instead of only rewarding at the end, you give small treats for getting closer. This helps the pup learn faster because it gets feedback every step, not just when it reaches the ball."
        case .sit:
            return "The pup tries an action (sit or move). You tell it \"good\" or \"bad.\" It remembers this and next time it's more likely to pick the action you rewarded. That's reinforcement."
        case .maze:
            return "Should the pup try a new path it hasn't explored, or stick with one that worked before? Early on, exploring is key. Later, it should exploit what it learned. This balance is called epsilon-greedy."
        case .patrol:
            return "The pup needs to learn a sequence: visit A, then B, then C. The right move depends on where it is AND which checkpoint is next. It must learn a full plan, not just one move."
        case .sock:
            return "The pup has to reach the ball, but there's a stinky sock on the grid. Stepping on it gives a big penalty. The pup must learn to chase the goal while avoiding danger — just like how AI learns to dodge obstacles."
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

    // MARK: - Cards

    private func conceptCard(title: String, body: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(levelType.accentColor)
                .frame(width: 36, height: 36)
                .background(levelType.accentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text(body)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
    }

    private var howToPlayCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("How to play")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            ForEach(Array(playSteps.enumerated()), id: \.offset) { i, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(levelType.accentColor, in: Circle())

                    Text(step)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 12))
    }

    private var playSteps: [String] {
        switch levelType {
        case .fetch: return [
            "Tap Step — the pup picks a direction",
            "See if it moved closer to the ball",
            "Tap Treat (good move) or Bad (wrong way)"
        ]
        case .sit: return [
            "Tap Sit to give the command",
            "Tap Step to see what the pup does",
            "Stayed still? Treat! Moved? Bad!"
        ]
        case .maze: return [
            "Pup needs to reach the bone",
            "Reward moves toward the goal",
            "Punish wrong turns and wall hits"
        ]
        case .patrol: return [
            "Pup must visit checkpoints in order",
            "Reward moves toward the next checkpoint",
            "It has to learn the entire route"
        ]
        case .sock: return [
            "Pup must reach the 🎾 ball",
            "Avoid the 🧦 stinky sock at all costs",
            "Sock = big penalty, ball = big reward"
        ]
        }
    }
}
