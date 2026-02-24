import SpriteKit
import UIKit

enum PetAnim: Int, CaseIterable {
    case walk = 0
    case idle = 1
    case happy = 2
    case sad = 3
}

@MainActor
struct SpriteLoader {
    static let sheetName = "sprite123"
    static let columns = 4
    static let rows = 4
    static let framePixels: CGFloat = 256

    static func loadAllRows() -> [PetAnim: [SKTexture]] {
        guard let image = loadSheetImage() else { return [:] }
        guard let cgImage = image.cgImage else { return [:] }

        var result: [PetAnim: [SKTexture]] = [:]
        for anim in PetAnim.allCases {
            let row = anim.rawValue
            var frames: [SKTexture] = []
            for col in 0..<columns {
                let rect = CGRect(
                    x: CGFloat(col) * framePixels,
                    y: CGFloat(row) * framePixels,
                    width: framePixels,
                    height: framePixels
                )
                if let cropped = cgImage.cropping(to: rect) {
                    let tex = SKTexture(cgImage: cropped)
                    tex.filteringMode = .nearest
                    frames.append(tex)
                }
            }
            result[anim] = frames
        }
        return result
    }

    private static func loadSheetImage() -> UIImage? {
        if let img = UIImage(named: sheetName) { return img }
        if let url = Bundle.main.url(forResource: sheetName, withExtension: "png") {
            return UIImage(contentsOfFile: url.path)
        }
        if let url = Bundle.main.url(forResource: sheetName, withExtension: "png", subdirectory: "Resources") {
            return UIImage(contentsOfFile: url.path)
        }
        return nil
    }
}
