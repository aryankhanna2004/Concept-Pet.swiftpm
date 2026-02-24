import SwiftUI
import UIKit

enum Theme {
    // MARK: - Adaptive colors

    static let green = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.85, blue: 0.50, alpha: 1)
            : UIColor(red: 0.26, green: 0.72, blue: 0.45, alpha: 1)
    })

    static let red = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.40, blue: 0.35, alpha: 1)
            : UIColor(red: 0.88, green: 0.30, blue: 0.26, alpha: 1)
    })

    static let orange = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.70, blue: 0.25, alpha: 1)
            : UIColor(red: 0.95, green: 0.60, blue: 0.18, alpha: 1)
    })

    static let blue = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.68, blue: 1.0, alpha: 1)
            : UIColor(red: 0.35, green: 0.60, blue: 0.95, alpha: 1)
    })

    static let purple = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.48, blue: 0.95, alpha: 1)
            : UIColor(red: 0.50, green: 0.35, blue: 0.80, alpha: 1)
    })

    static let teal = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.85, blue: 0.80, alpha: 1)
            : UIColor(red: 0.20, green: 0.68, blue: 0.65, alpha: 1)
    })

    static let bg = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
            : UIColor(red: 0.97, green: 0.96, blue: 0.94, alpha: 1)
    })

    static let card = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.17, blue: 0.19, alpha: 1)
            : UIColor.white
    })

    static let gridFloor = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.30, blue: 0.20, alpha: 1)
            : UIColor(red: 0.88, green: 0.94, blue: 0.82, alpha: 1)
    })

    static let gridWall = Color(uiColor: UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.30, green: 0.24, blue: 0.18, alpha: 1)
            : UIColor(red: 0.55, green: 0.45, blue: 0.35, alpha: 1)
    })

    static let sceneBgLight = UIColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1)
    static let sceneBgDark = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
    static let sceneFloorLight = UIColor(red: 0.82, green: 0.90, blue: 0.74, alpha: 1)
    static let sceneFloorDark = UIColor(red: 0.22, green: 0.30, blue: 0.20, alpha: 1)
    static let sceneWallLight = UIColor(red: 0.55, green: 0.45, blue: 0.35, alpha: 1)
    static let sceneWallDark = UIColor(red: 0.30, green: 0.24, blue: 0.18, alpha: 1)

    // MARK: - Typography

    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let heading = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
    static let small = Font.system(size: 10, weight: .medium, design: .rounded)

    static let radius: CGFloat = 14

    // MARK: - Legacy aliases

    static let accentGreen = green
    static let softRed = red
    static let warmOrange = orange
    static let skyBlue = blue
    static let deepPurple = purple
    static let background = bg
    static let cardBackground = card
    static let titleFont = title
    static let headingFont = heading
    static let bodyFont = body
    static let captionFont = caption
    static let smallFont = small
    static let cornerRadius = radius
    static let tileSize: CGFloat = 60

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
}
