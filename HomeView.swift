import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(GameState.self) private var state
    @State private var pulse: CGFloat = 1.0
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                    Spacer()

                    dogAvatar
                        .frame(width: 150, height: 150)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    Spacer().frame(height: 32)

                    Text("Concept Pet")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Spacer().frame(height: 8)

                    Text("Train an AI puppy with rewards")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .opacity(appeared ? 1 : 0)

                    if state.treatCount > 0 || !state.bestScores.isEmpty {
                        Spacer().frame(height: 20)

                        HStack(spacing: 20) {
                            if state.treatCount > 0 {
                                statPill(
                                    icon: "heart.fill",
                                    value: "\(state.treatCount)",
                                    color: Theme.green
                                )
                            }
                            if let best = state.bestScores.values.min() {
                                statPill(
                                    icon: "trophy.fill",
                                    value: "\(best) best",
                                    color: Theme.orange
                                )
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                    }

                    Spacer()
                    Spacer()

                    NavigationLink(destination: LevelSelectView()) {
                        Text("Start Training")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Theme.green, in: Capsule())
                    }
                    .padding(.horizontal, 48)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                    Spacer().frame(height: 48)
                }
                .padding()
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    pulse = 1.05
                }
                withAnimation(.easeOut(duration: 0.7)) {
                    appeared = true
                }
            }
        }
    }

    private func statPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.10), in: Capsule())
    }

    private var dogAvatar: some View {
        ZStack {
            Circle()
                .fill(Theme.green.opacity(0.08))
                .frame(width: 150, height: 150)

            Circle()
                .fill(Theme.green.opacity(0.05))
                .frame(width: 120, height: 120)

            spriteImage
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .scaleEffect(pulse)
        }
    }

    private var spriteImage: Image {
        guard let sheet = UIImage(named: "sprite123") ?? bundleSprite(),
              let cg = sheet.cgImage,
              let cropped = cg.cropping(to: CGRect(x: 0, y: 256, width: 256, height: 256)) else {
            return Image(systemName: "pawprint.fill")
        }
        return Image(uiImage: UIImage(cgImage: cropped))
    }

    private func bundleSprite() -> UIImage? {
        if let url = Bundle.main.url(forResource: "sprite123", withExtension: "png") {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }
}
