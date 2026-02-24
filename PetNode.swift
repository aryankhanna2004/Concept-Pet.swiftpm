import SpriteKit

enum PetAnimationState {
    case idle, walkUp, walkDown, walkLeft, walkRight, happy, sad, sit
}

@MainActor
final class PetNode: SKNode {
    private enum ActionKey {
        static let internalMotion = "pet.internal.motion"
    }

    private let sprite: SKSpriteNode
    private var frames: [PetAnim: [SKTexture]] = [:]
    private(set) var animationState: PetAnimationState = .idle
    private let petSize: CGFloat
    private var useFallback = false

    init(size: CGFloat = 48) {
        self.petSize = size
        self.sprite = SKSpriteNode()
        sprite.size = CGSize(width: size, height: size)
        super.init()
        addChild(sprite)
        loadSprites()
        playIdle()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func loadSprites() {
        frames = SpriteLoader.loadAllRows()
        if frames[.idle]?.isEmpty != false {
            useFallback = true
            buildFallbackDog()
        }
    }

    func setState(_ state: PetAnimationState) {
        guard state != animationState else { return }
        animationState = state
        sprite.removeAllActions()
        removeAction(forKey: ActionKey.internalMotion)
        setScale(1.0)
        sprite.xScale = abs(sprite.xScale)

        if useFallback {
            playFallbackAnimation(state)
            return
        }

        switch state {
        case .idle:      playIdle()
        case .walkRight: playWalk(flipX: false)
        case .walkLeft:  playWalk(flipX: true)
        case .walkUp:    playWalk(flipX: false)
        case .walkDown:  playWalk(flipX: false)
        case .happy:     playHappy()
        case .sad:       playSad()
        case .sit:       playSit()
        }
    }

    // MARK: - Sprite animations

    private func playIdle() {
        guard let row1 = frames[.idle], row1.count >= 2 else { return }
        let standFrames = Array(row1[0...1])
        let anim = SKAction.animate(with: standFrames, timePerFrame: 0.5)
        sprite.run(.repeatForever(anim))
    }

    private func playWalk(flipX: Bool) {
        guard let f = frames[.walk], !f.isEmpty else { playIdle(); return }
        sprite.xScale = flipX ? -abs(sprite.xScale) : abs(sprite.xScale)
        let anim = SKAction.animate(with: f, timePerFrame: 0.08)
        sprite.run(.repeatForever(anim))
    }

    private func playSit() {
        guard let row1 = frames[.idle], row1.count >= 3 else { playIdle(); return }
        sprite.texture = row1[2]
    }

    private func playHappy() {
        guard let row2 = frames[.happy], row2.count >= 2 else { playIdle(); return }
        let eatAnim = SKAction.animate(with: row2, timePerFrame: 0.18)
        sprite.run(.repeat(eatAnim, count: 2)) { [weak self] in
            self?.animationState = .idle
            self?.playIdle()
        }
        let bounce = SKAction.sequence([
            .moveBy(x: 0, y: 4, duration: 0.08),
            .moveBy(x: 0, y: -4, duration: 0.08)
        ])
        run(.repeat(bounce, count: row2.count * 2), withKey: ActionKey.internalMotion)
    }

    private func playSad() {
        guard let row3 = frames[.sad], !row3.isEmpty else { playIdle(); return }
        let sadAnim = SKAction.animate(with: row3, timePerFrame: 0.25)
        let hold = SKAction.wait(forDuration: 0.6)
        sprite.run(.sequence([sadAnim, hold])) { [weak self] in
            self?.animationState = .idle
            self?.playIdle()
        }
        let droop = SKAction.sequence([
            .moveBy(x: 0, y: -4, duration: 0.3),
            .wait(forDuration: row3.count > 1 ? Double(row3.count) * 0.25 + 0.3 : 0.8),
            .moveBy(x: 0, y: 4, duration: 0.3)
        ])
        run(droop, withKey: ActionKey.internalMotion)
    }

    // MARK: - Fallback shape dog

    private func buildFallbackDog() {
        sprite.isHidden = true
        let s = petSize

        let body = SKShapeNode(ellipseOf: CGSize(width: s * 0.6, height: s * 0.45))
        body.fillColor = SKColor(red: 0.85, green: 0.65, blue: 0.35, alpha: 1)
        body.strokeColor = SKColor(red: 0.6, green: 0.45, blue: 0.2, alpha: 1)
        body.lineWidth = 1.5
        addChild(body)

        let headR = s * 0.28
        let head = SKShapeNode(circleOfRadius: headR)
        head.fillColor = SKColor(red: 0.88, green: 0.70, blue: 0.40, alpha: 1)
        head.strokeColor = SKColor(red: 0.6, green: 0.45, blue: 0.2, alpha: 1)
        head.lineWidth = 1.5
        head.position = CGPoint(x: 0, y: s * 0.22 + headR * 0.5)
        addChild(head)

        for xOff in [-headR * 0.35, headR * 0.35] {
            let eye = SKShapeNode(circleOfRadius: headR * 0.15)
            eye.fillColor = .black
            eye.strokeColor = .clear
            eye.position = CGPoint(x: xOff, y: headR * 0.1)
            head.addChild(eye)
        }

        let nose = SKShapeNode(circleOfRadius: headR * 0.12)
        nose.fillColor = SKColor(red: 0.15, green: 0.1, blue: 0.1, alpha: 1)
        nose.strokeColor = .clear
        nose.position = CGPoint(x: 0, y: -headR * 0.2)
        head.addChild(nose)
    }

    private func playFallbackAnimation(_ state: PetAnimationState) {
        removeAction(forKey: ActionKey.internalMotion)
        setScale(1.0)
        switch state {
        case .walkUp, .walkDown, .walkLeft, .walkRight:
            let bob = SKAction.sequence([
                .moveBy(x: 0, y: 3, duration: 0.15),
                .moveBy(x: 0, y: -3, duration: 0.15)
            ])
            run(.repeatForever(bob), withKey: ActionKey.internalMotion)
        case .happy:
            let bounce = SKAction.sequence([
                .moveBy(x: 0, y: 8, duration: 0.12),
                .moveBy(x: 0, y: -8, duration: 0.12)
            ])
            run(.repeat(bounce, count: 3), withKey: ActionKey.internalMotion)
        case .sad:
            run(.scaleY(to: 0.85, duration: 0.3), withKey: ActionKey.internalMotion)
        case .sit:
            run(.scaleY(to: 0.85, duration: 0.2), withKey: ActionKey.internalMotion)
        case .idle:
            break
        }
    }
}
