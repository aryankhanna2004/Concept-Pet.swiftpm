import SwiftUI
import ImagePlayground
import PhotosUI

@available(iOS 18.1, *)
struct PlaygroundSheetWrapper<C: View>: View {
    @Binding var isPresented: Bool
    let sourceImage: Image?
    let onCompletion: (URL) -> Void
    @ViewBuilder let wrapped: () -> C

    var body: some View {
        wrapped()
            .imagePlaygroundSheet(
                isPresented: $isPresented,
                concept: "cute 2D pixel art style dog, game sprite, retro pixel art",
                sourceImage: sourceImage,
                onCompletion: onCompletion
            )
    }
}

@available(iOS 18.1, *)
struct CustomizePupButtonContent: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var showPlaygroundUnavailable: Bool
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

    var body: some View {
        if supportsImagePlayground {
            PhotosPicker(
                selection: $selectedPhoto,
                matching: .images
            ) {
                buttonLabel
            }
        } else {
            Button {
                showPlaygroundUnavailable = true
            } label: {
                buttonLabel
            }
        }
    }

    private var buttonLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 14, weight: .semibold))
            Text("Create Your Pup")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Theme.purple)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.purple.opacity(0.10), in: Capsule())
    }
}
