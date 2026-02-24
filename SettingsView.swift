import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(GameState.self) private var gameState
    @Environment(\.dismiss) private var dismiss
    @State private var expandedLevel: LevelType? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        enthusiastToggleCard
                        if settings.enthusiastMode {
                            rewardSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .animation(.easeInOut(duration: 0.3), value: settings.enthusiastMode)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    // MARK: - Enthusiast Toggle

    private var enthusiastToggleCard: some View {
        @Bindable var s = settings
        return VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Theme.purple.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "atom")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.purple)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Enthusiast Mode")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text("Unlocks deep algorithm details & reward controls")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $s.enthusiastMode)
                    .tint(Theme.purple)
                    .labelsHidden()
            }

            if settings.enthusiastMode {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    label("What you unlock:", icon: "lock.open.fill", color: Theme.purple)
                    featureRow("Deep Dive section on every lesson intro")
                    featureRow("Live ε (epsilon) + Q-value stats in-game")
                    featureRow("Per-lesson reward & penalty sliders below")
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            settings.enthusiastMode
                ? RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.purple.opacity(0.4), lineWidth: 1.5)
                : nil
        )
    }

    // MARK: - Reward Section

    private var rewardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.purple)
                Text("Reward Tuning")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button {
                    settings.resetRewards()
                    expandedLevel = nil
                } label: {
                    Text("Reset All")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.purple)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.purple.opacity(0.10), in: Capsule())
                }
            }

            Text("Adjust how strongly treats and penalties affect learning. Higher treat = pup learns faster but may overfit. Higher penalty = pup avoids danger more aggressively.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                ForEach(LevelType.allCases) { level in
                    rewardCard(for: level)
                }
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func rewardCard(for level: LevelType) -> some View {
        @Bindable var s = settings
        let isExpanded = expandedLevel == level

        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    expandedLevel = isExpanded ? nil : level
                }
            } label: {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(level.accentColor.opacity(0.12))
                            .frame(width: 32, height: 32)
                        Image(systemName: level.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(level.accentColor)
                    }
                    Text(level.title)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()

                    HStack(spacing: 4) {
                        Text("🦴 \(String(format: "%.1f", settings.treat(for: level)))")
                        Text("·")
                        Text("👎 \(String(format: "%.1f", settings.penalty(for: level)))")
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Theme.bg.opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 14) {
                    rewardSlider(
                        title: "Treat reward",
                        emoji: "🦴",
                        value: Binding(
                            get: { settings.treat(for: level) },
                            set: { s.treatReward[level] = $0 }
                        ),
                        range: 0.5...5.0,
                        color: Theme.green
                    )

                    rewardSlider(
                        title: "Penalty magnitude",
                        emoji: "👎",
                        value: Binding(
                            get: { settings.penalty(for: level) },
                            set: { s.penaltyReward[level] = $0 }
                        ),
                        range: 0.5...5.0,
                        color: Theme.red
                    )

                    HStack {
                        Spacer()
                        Button {
                            withAnimation {
                                s.treatReward[level] = AppSettings.defaultTreat
                                s.penaltyReward[level] = AppSettings.defaultPenalty
                            }
                        } label: {
                            Text("Reset \(level.title)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(level.accentColor)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Theme.bg.opacity(0.3), in: RoundedRectangle(cornerRadius: 10))
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }

    private func rewardSlider(title: String, emoji: String, value: Binding<Double>, range: ClosedRange<Double>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(emoji) \(title)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(String(format: "%.1f", value.wrappedValue))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(color)
            }
            Slider(value: value, in: range, step: 0.5)
                .tint(color)
        }
    }

    // MARK: - Helpers

    private func label(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
        }
    }

    private func featureRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.purple.opacity(0.7))
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
