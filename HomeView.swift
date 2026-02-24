import SwiftUI
import UIKit
import PhotosUI

struct HomeView: View {
    @Environment(GameState.self) private var state
    @Environment(AppSettings.self) private var settings
    @State private var pulse: CGFloat = 1.0
    @State private var appeared = false
    @State private var showPlayground = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var dogSourceImage: Image?
    @State private var generatedPetURL: URL?
    @State private var generatedPetImage: UIImage?
    @State private var showPlaygroundUnavailable = false
    @State private var showSettings = false

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
                        .accessibilityLabel("Your pup")
                        .accessibilityHint("This is your AI pet. Upload a photo to make it look like your real dog.")

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
                                .accessibilityLabel("\(state.treatCount) treats given")
                            }
                            if let best = state.bestScores.values.min() {
                                statPill(
                                    icon: "trophy.fill",
                                    value: "\(best) best",
                                    color: Theme.orange
                                )
                                .accessibilityLabel("Best score: \(best) steps")
                            }
                        }
                        .opacity(appeared ? 1 : 0)
                    }

                    Spacer()
                    Spacer()

                    VStack(spacing: 12) {
                        NavigationLink(destination: LevelSelectView()) {
                            Text("Start Training")
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.green, in: Capsule())
                        }
                        .accessibilityLabel("Start Training")
                        .accessibilityHint("Opens the list of lessons where you can train your pup.")

                        customizePupButton
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
                loadSavedPet()
            }
            .modifier(ImagePlaygroundModifier(
                isPresented: $showPlayground,
                sourceImage: dogSourceImage,
                onCompletion: handleGeneratedImage
            ))
            .onChange(of: selectedPhoto) { _, item in
                Task { await loadPhoto(item) }
            }
            .alert("Image Playground Unavailable", isPresented: $showPlaygroundUnavailable) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Turn on Apple Intelligence in Settings > Apple Intelligence & Siri, then try again.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: settings.enthusiastMode ? "atom" : "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(settings.enthusiastMode ? Theme.purple : Theme.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environment(settings)
                    .environment(state)
            }
        }
    }

    // MARK: - Customize Button

    @ViewBuilder
    private var customizePupButton: some View {
        if #available(iOS 18.1, *) {
            CustomizePupButtonContent(
                selectedPhoto: $selectedPhoto,
                showPlaygroundUnavailable: $showPlaygroundUnavailable
            )
        }
    }

    // MARK: - Photo Loading

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        dogSourceImage = Image(uiImage: uiImage)
        showPlayground = true
    }

    // MARK: - Generated Image Handling

    private func handleGeneratedImage(url: URL) {
        guard let data = try? Data(contentsOf: url),
              let img = UIImage(data: data) else { return }
        generatedPetImage = img
        generatedPetURL = url
        savePet(img)
    }

    private var savedPetURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("custom_pet.png")
    }

    private func savePet(_ image: UIImage) {
        if let data = image.pngData() {
            try? data.write(to: savedPetURL)
        }
    }

    private func loadSavedPet() {
        if let data = try? Data(contentsOf: savedPetURL),
           let img = UIImage(data: data) {
            generatedPetImage = img
        }
    }

    // MARK: - Stat Pill

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

    // MARK: - Dog Avatar

    private var dogAvatar: some View {
        ZStack {
            Circle()
                .fill(Theme.green.opacity(0.08))
                .frame(width: 150, height: 150)

            Circle()
                .fill(Theme.green.opacity(0.05))
                .frame(width: 120, height: 120)

            if let custom = generatedPetImage {
                Image(uiImage: custom)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .scaleEffect(pulse)
            } else {
                spriteImage
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .scaleEffect(pulse)
            }
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

// MARK: - Image Playground Modifier

private struct ImagePlaygroundModifier: ViewModifier {
    @Binding var isPresented: Bool
    let sourceImage: Image?
    let onCompletion: (URL) -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.1, *) {
            PlaygroundSheetWrapper(
                isPresented: $isPresented,
                sourceImage: sourceImage,
                onCompletion: onCompletion
            ) { content }
        } else {
            content
        }
    }
}
