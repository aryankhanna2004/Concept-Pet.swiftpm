# Concept Pet

**Train an AI puppy with rewards — and learn how reinforcement learning works.**

Concept Pet is an iOS app that teaches AI and reinforcement learning concepts through hands-on gameplay. You train a virtual puppy by giving treats (positive rewards) or saying "no" (negative rewards), and watch it get smarter over time using a real Q-learning algorithm.

## Features

### Training Levels

Each level teaches a different reinforcement learning concept:

| Level | Concept | Description |
|---|---|---|
| **Ball Fetch** | Reward Shaping | Guide your pup toward the ball with incremental rewards |
| **Sit Command** | Reinforcement | Teach your dog to sit on command through feedback |
| **Maze Runner** | Exploration vs. Exploitation | Help your pup decide when to try new paths or stick with what works |
| **Patrol Route** | Policy Learning | Train a complete patrol plan across multiple waypoints |
| **Stinky Sock** | Avoidance Learning | Chase the ball while learning to avoid danger |

### Brain Map

Visualize your puppy's Q-table in real time. Each cell shows which direction the pup would move and how confident it is — watch the brain map evolve as your pup learns from your feedback.

### Customize Your Pup

Upload a photo of your real dog and use Apple's Image Playground to generate a unique AI-styled avatar for your in-app pet. (Requires iOS 18.1+ with Apple Intelligence enabled.)

### Enthusiast Mode

Toggle advanced settings to fine-tune treat and penalty reward values per level for deeper experimentation with the RL algorithm.

## Tech Stack

- **SwiftUI** — UI framework
- **SpriteKit** — Game rendering (grid environments, pet animation)
- **Q-Learning** — Tabular reinforcement learning with configurable learning rate, discount factor, and epsilon-greedy exploration
- **Swift 6** — Full concurrency safety
- **Image Playground** — Apple Intelligence integration for pet customization

## Requirements

- iOS 17.0+
- iPhone or iPad
- Xcode 16+ to build

## Project Structure

```
Concept Pet.swiftpm/
├── MyApp.swift              # App entry point
├── ContentView.swift        # Root navigation
├── HomeView.swift           # Home screen with pet avatar
├── LevelSelectView.swift    # Level picker
├── LevelIntroView.swift     # Pre-level concept explainer
├── GameView.swift           # Training UI (treat/no buttons)
├── GameScene.swift          # SpriteKit game scene
├── GameState.swift          # Central state + level definitions
├── BrainMapView.swift       # Q-table visualization
├── RLAgent.swift            # RL agent (epsilon-greedy + Q-learning)
├── QTable.swift             # Q-table implementation
├── RLEnvironment.swift      # Environment protocol
├── FetchEnvironment.swift   # Ball fetch grid environment
├── SitEnvironment.swift     # Sit command environment
├── MazeEnvironment.swift    # Maze navigation environment
├── PatrolEnvironment.swift  # Waypoint patrol environment
├── SockEnvironment.swift    # Fetch + avoidance environment
├── PetNode.swift            # SpriteKit pet node
├── SpriteLoader.swift       # Sprite sheet loading
├── AppSettings.swift        # User preferences + reward tuning
├── SettingsView.swift       # Settings UI
├── Theme.swift              # Colors and typography
└── Resources/
    └── sprite123.png        # Pet sprite sheet
```

## Building

1. Open `Concept Pet.swiftpm` in Xcode 16+
2. Select an iPhone or iPad simulator
3. Build and run (Cmd + R)

## License

All rights reserved.
