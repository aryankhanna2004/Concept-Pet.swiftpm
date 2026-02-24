import SwiftUI
import SpriteKit

struct GameView: View {
    let levelType: LevelType
    @Environment(GameState.self) private var state
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss
    @State private var scene: GameScene?
    @State private var showBrainMap = false
    @State private var autoPlay = false
    @State private var showHints = false
    @State private var autoTask: Task<Void, Never>?
    @State private var showOnboarding = true
    @State private var successData: (steps: Int, show: Bool)? = nil
    @State private var waiting = false
    @State private var hint = "Tap Step to start"
    @State private var hintGood: Bool? = nil
    @State private var tick = 0

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                hud.padding(.horizontal, 12).padding(.top, 4)
                if showHints {
                    hintBar.padding(.horizontal, 12).padding(.top, 4)
                }

                if let scene {
                    SpriteView(scene: scene)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                }

                controls
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 8)
                    .background(
                        Color(red: 0.94, green: 0.93, blue: 0.90)
                            .shadow(.drop(color: .black.opacity(0.10), radius: 10, y: -3))
                    )
            }

            if showOnboarding { onboarding }
            if let data = successData, data.show { successOverlay(steps: data.steps) }
        }
        .navigationTitle(levelType.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarItems }
        .onAppear { setupScene() }
        .onDisappear { autoTask?.cancel() }
        .onChange(of: autoPlay) { _, on in
            if on { startAuto() } else { stopAuto() }
        }
    }

    // MARK: - HUD

    private var hud: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Try \(agent.totalEpisodes + 1)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                if agent.bestEpisodeSteps < Int.max {
                    Label("Best \(agent.bestEpisodeSteps)", systemImage: "trophy.fill")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.orange)
                }

                Spacer()

                Text("\(agent.episodeSteps)/30")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
            }

            if settings.enthusiastMode {
                enthusiastHUD
            }
        }
    }

    private var enthusiastHUD: some View {
        let qVals = topQValues
        return HStack(spacing: 0) {
            // Epsilon pill
            HStack(spacing: 4) {
                Text("ε")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.purple)
                Text(String(format: "%.3f", agent.epsilon))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Theme.purple)
                    .monospacedDigit()

                // Epsilon bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Theme.purple.opacity(0.12)).frame(height: 4)
                        Capsule().fill(Theme.purple.opacity(0.6))
                            .frame(width: geo.size.width * agent.epsilon, height: 4)
                    }
                }
                .frame(width: 44, height: 8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Theme.purple.opacity(0.07), in: Capsule())

            Spacer()

            // Top Q-values for current state
            if !qVals.isEmpty {
                HStack(spacing: 6) {
                    ForEach(qVals.prefix(3), id: \.action) { item in
                        HStack(spacing: 2) {
                            Text(actionArrow(item.action))
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(item.value >= 0 ? Theme.green : Theme.red)
                            Text(String(format: "%.1f", item.value))
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundStyle(item.value >= 0 ? Theme.green : Theme.red)
                                .monospacedDigit()
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.card.opacity(0.8), in: Capsule())
            }
        }
        .animation(.easeInOut(duration: 0.2), value: tick)
    }

    private struct QEntry: Identifiable {
        let action: String
        let value: Double
        var id: String { action }
    }

    private var topQValues: [QEntry] {
        guard let scene, let gs = scene.gameState else { return [] }
        let env = gs.environment(for: levelType)
        let state = env.currentState
        let actions = env.availableActions
        let qTable = gs.qTable(for: levelType)
        return actions
            .map { QEntry(action: $0, value: qTable.getValue(state: state, action: $0)) }
            .sorted { abs($0.value) > abs($1.value) }
    }

    private func actionArrow(_ action: String) -> String {
        switch action {
        case "up":    return "↑"
        case "down":  return "↓"
        case "left":  return "←"
        case "right": return "→"
        case "sit":   return "🐶"
        case "move":  return "🐕"
        default:      return action.prefix(1).uppercased()
        }
    }

    // MARK: - Hint

    private var hintBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(hintGood == true ? Theme.green : hintGood == false ? Theme.red : Theme.blue)
                .frame(width: 8, height: 8)
            Text(hint)
                .font(Theme.caption)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((hintGood == true ? Theme.green : hintGood == false ? Theme.red : Theme.blue).opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: 8) {
                Button {
                    showBrainMap.toggle()
                    scene?.showHeatmap = showBrainMap
                } label: {
                    Label("Brain", systemImage: showBrainMap ? "brain.fill" : "brain")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(showBrainMap ? Theme.green : Theme.purple)
                }
                Menu {
                    Toggle(isOn: $showHints) {
                        Label("Show Hints", systemImage: "lightbulb")
                    }
                    Toggle(isOn: $autoPlay) {
                        Label("Auto Train", systemImage: "sparkles")
                    }
                    Button("Restart Round", systemImage: "arrow.clockwise") {
                        scene?.resetEpisode()
                        waiting = false
                        if showHints {
                            hint = "New round!"
                            hintGood = nil
                            tick += 1
                        }
                    }
                    Divider()
                    Button("Reset Brain", systemImage: "arrow.counterclockwise") {
                        state.resetLevel(levelType)
                        scene?.resetEpisode()
                        waiting = false
                        showBrainMap = false
                        scene?.showHeatmap = false
                        if showHints {
                            hint = "Brain reset!"
                            hintGood = nil
                            tick += 1
                        }
                    }
                } label: {
                    Label("Settings", systemImage: "ellipsis.circle")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    // MARK: - Controls

    private var controls: some View {
        VStack(spacing: 10) {
            if levelType == .sit && !state.sitEnv.commandActive {
                Button {
                    state.sitEnv.issueCommand()
                    hint = "You said Sit! Now tap Step."
                    hintGood = nil
                    tick += 1
                } label: {
                    Label("Say \"Sit!\"", systemImage: "hand.raised.fill")
                        .font(Theme.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Theme.blue, in: RoundedRectangle(cornerRadius: 10))
                }
            }

            HStack(spacing: 12) {
                Button { deliverReward(-settings.penalty(for: levelType)) } label: {
                    HStack(spacing: 4) {
                        Text("👎")
                        Text("Bad")
                    }
                        .font(Theme.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.red, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!waiting || autoPlay)
                .opacity((waiting && !autoPlay) ? 1 : 0.3)

                Button { performStep() } label: {
                    Label("Step", systemImage: "play.fill")
                        .font(Theme.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.blue, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(waiting || autoPlay)
                .opacity((!waiting && !autoPlay) ? 1 : 0.3)

                Button { deliverReward(settings.treat(for: levelType)) } label: {
                    HStack(spacing: 4) {
                        Text("🦴")
                        Text("Treat")
                    }
                        .font(Theme.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Theme.green, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!waiting || autoPlay)
                .opacity((waiting && !autoPlay) ? 1 : 0.3)
            }

        }
        .padding(.vertical, 2)
    }

    // MARK: - Onboarding

    private var onboarding: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
                .onTapGesture { withAnimation { showOnboarding = false } }

            VStack(spacing: 18) {
                Image(systemName: levelType.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(levelType.accentColor)

                Text(levelType.title)
                    .font(Theme.title)
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { i, s in
                        Label(s, systemImage: "\(i + 1).circle.fill")
                            .font(Theme.body)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }

                Text(levelType.aiConceptExplainer)
                    .font(Theme.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Button {
                    withAnimation { showOnboarding = false }
                } label: {
                    Text("Got it!")
                        .font(Theme.heading)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 10)
                        .background(levelType.accentColor, in: Capsule())
                }
            }
            .padding(28)
        }
    }

    private var steps: [String] {
        switch levelType {
        case .fetch: return ["Tap Step, pup picks a direction", "See if it moved closer or not", "Tap Good or Bad to teach it"]
        case .sit: return ["Tap Sit to give the command", "Tap Step to see what pup does", "Stayed still? Good! Moved? Bad!"]
        case .maze: return ["Pup must find the bone", "Reward closer, punish wrong turns", "Watch it learn the path!"]
        case .patrol: return ["Pup must visit waypoints in order", "Reward moves toward the next point", "It must learn a full route!"]
        case .sock: return ["Pup must reach the 🎾 ball", "Avoid the 🧦 stinky sock!", "Sock = big penalty, ball = reward"]
        }
    }

    // MARK: - Success

    private func successOverlay(steps: Int) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { }

            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.orange)

                Text("You did it!")
                    .font(Theme.title)
                    .foregroundStyle(.white)

                Text("\(steps) steps")
                    .font(Theme.heading)
                    .foregroundStyle(.white.opacity(0.9))

                if let best = state.bestScores[levelType], best == steps {
                    Label("New best!", systemImage: "trophy.fill")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.orange)
                }

                HStack(spacing: 12) {
                    Button {
                        successData = nil
                        scene?.resetEpisode()
                        hint = "Tap Step to start"
                        hintGood = nil
                        tick += 1
                    } label: {
                        Text("Try again")
                            .font(Theme.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    }

                    Button {
                        successData = nil
                        scene?.resetEpisode()
                        dismiss()
                    } label: {
                        Text("Lessons")
                            .font(Theme.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(levelType.accentColor, in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(28)
            .background(Color(red: 0.13, green: 0.13, blue: 0.15).opacity(0.95), in: RoundedRectangle(cornerRadius: 20))
            .padding(24)
        }
    }

    // MARK: - Logic

    private var agent: RLAgent { state.agent(for: levelType) }

    private func setupScene() {
        let s = GameScene(size: CGSize(width: 400, height: 420))
        s.scaleMode = .resizeFill
        s.configure(level: levelType, state: state)
        s.onGoalReached = { steps in
            if autoPlay {
                s.resetEpisode()
                waiting = false
                return
            }
            successData = (steps: steps, show: true)
        }
        scene = s
    }

    private func performStep() {
        guard let scene, !scene.waitingForReward else { return }
        scene.performStep()
        if scene.waitingForReward {
            waiting = true
            if showHints {
                updateHint()
            }
        } else {
            if showHints {
                hint = "Round done, new one coming..."
                hintGood = nil
            }
            waiting = false
        }
        tick += 1
    }

    private func updateHint() {
        guard let scene, let gs = scene.gameState else { return }
        let r = scene.pendingAutoReward

        switch levelType {
        case .fetch:
            let env = gs.fetchEnv
            if env.isGoalReached {
                hint = "Fetched the ball! Tap Treat!"
                hintGood = true
            } else if env.didBounce {
                hint = "Bonked the wall! Tap Bad!"
                hintGood = false
            } else if env.movedCloser {
                hint = "\(env.currentDistance) tiles away — getting closer! Treat!"
                hintGood = true
            } else {
                hint = "Moved further from the ball. Bad!"
                hintGood = false
            }

        case .sit:
            let env = gs.sitEnv
            if env.isGoalReached {
                hint = "Stayed still 3 times — good dog! Treat!"
                hintGood = true
            } else if !env.commandActive {
                hint = "Tap \"Sit!\" first to give the command."
                hintGood = nil
            } else if env.dogMoved {
                hint = "Pup moved instead of sitting! Bad!"
                hintGood = false
            } else {
                hint = "Stayed still! (\(env.stillnessCount)/\(env.requiredStillness)) Treat!"
                hintGood = true
            }

        case .maze:
            let env = gs.mazeEnv
            if env.isGoalReached {
                hint = "Found the bone! Tap Treat!"
                hintGood = true
            } else if env.hitWall {
                hint = "Hit a wall! Tap Bad!"
                hintGood = false
            } else if env.movedCloser {
                hint = "\(env.currentDistance) tiles to bone — closer! Treat!"
                hintGood = true
            } else {
                hint = "Moved away from the bone. Bad!"
                hintGood = false
            }

        case .patrol:
            let env = gs.patrolEnv
            if env.isGoalReached {
                hint = "Full patrol done! Treat!"
                hintGood = true
            } else if r >= 5.0 {
                hint = "Reached waypoint \(env.waypointsVisited)! Treat!"
                hintGood = true
            } else if env.didBounce {
                hint = "Hit the edge! Bad!"
                hintGood = false
            } else if env.movedCloser {
                hint = "\(env.currentDistance) to waypoint \(env.waypointIndex + 1) — closer! Treat!"
                hintGood = true
            } else {
                hint = "Wrong direction for waypoint \(env.waypointIndex + 1). Bad!"
                hintGood = false
            }

        case .sock:
            let env = gs.sockEnv
            if env.steppedOnSock {
                hint = "Stepped on the stinky sock! Bad!"
                hintGood = false
            } else if env.isGoalReached {
                hint = "Got the ball safely! Treat!"
                hintGood = true
            } else if env.didBounce {
                hint = "Bonked the wall! Bad!"
                hintGood = false
            } else if env.ballDistance < env.previousBallDistance {
                if env.sockDistance <= 1 {
                    hint = "Closer to ball but near the sock! Careful..."
                    hintGood = nil
                } else {
                    hint = "\(env.ballDistance) to ball — closer! Treat!"
                    hintGood = true
                }
            } else {
                hint = "Moved away from the ball. Bad!"
                hintGood = false
            }
        }
    }

    private func deliverReward(_ reward: Double) {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: reward > 0 ? .light : .medium).impactOccurred()
        #endif
        scene?.deliverReward(reward)
        waiting = false
        if showHints {
            hint = reward > 0 ? "Nice! Treat given." : "Nope! Pup noted that."
            hintGood = nil
            tick += 1
        }
    }

    private func startAuto() {
        autoTask = Task { @MainActor in
            while !Task.isCancelled {
                guard let scene else {
                    try? await Task.sleep(for: .milliseconds(100))
                    continue
                }

                if waiting {
                    scene.deliverAutoReward()
                    waiting = false
                    try? await Task.sleep(for: .milliseconds(80))
                } else {
                    scene.performStep()
                    if scene.waitingForReward {
                        waiting = true
                    }
                    try? await Task.sleep(for: .milliseconds(120))
                }

                if showHints {
                    let eps = Int(agent.epsilon * 100)
                    hint = "Training... \(eps)% random"
                    if agent.bestEpisodeSteps < Int.max {
                        hint += " | Best: \(agent.bestEpisodeSteps)"
                    }
                    hintGood = nil
                    tick += 1
                }
            }
        }
    }

    private func stopAuto() {
        autoTask?.cancel()
        autoTask = nil
        if showHints {
            hint = "Go ahead, tap Step."
            hintGood = nil
        }
    }
}
