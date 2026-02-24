import SwiftUI

struct LevelSelectView: View {
    @Environment(GameState.self) private var state
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 12)

                    Text("Pick a lesson to start training your pup.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                        .opacity(appeared ? 1 : 0)

                    VStack(spacing: 16) {
                        ForEach(Array(LevelType.allCases.enumerated()), id: \.element.id) { index, level in
                            NavigationLink(destination: LevelIntroView(levelType: level)) {
                                levelCard(level: level, index: index)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(level.title)
                            .accessibilityHint(level.description)
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer().frame(height: 32)
                }
            }
        }
        .navigationTitle("Lessons")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                appeared = true
            }
        }
    }

    private func levelCard(level: LevelType, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(level.accentColor.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: level.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(level.accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(level.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)

                        Spacer()

                        if let best = state.bestScores[level] {
                            HStack(spacing: 3) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 10))
                                Text("\(best)")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(Theme.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.orange.opacity(0.10), in: Capsule())
                            .accessibilityLabel("Best score: \(best) steps")
                        }
                    }

                    Text(level.description)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer().frame(height: 12)

            HStack(spacing: 0) {
                Text(level.aiConceptTag)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(level.accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(level.accentColor.opacity(0.08), in: Capsule())

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary.opacity(0.4))
            }
        }
        .padding(16)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 8)
        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.06), value: appeared)
    }
}
