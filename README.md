# Spider Solitaire

A classic Spider Solitaire card game built with **Godot 4.3+** and **GDScript**.

## Features

- **3 Difficulty Levels**: Easy (1 suit), Medium (2 suits), Hard (4 suits)
- **Drag & Drop**: Smooth card dragging with touch and mouse support
- **Undo**: Unlimited undo with full move history
- **Cross-Platform**: Target iOS, iPadOS, Android, Windows, macOS, Linux
- **Clean UI**: Custom-drawn cards, green felt table, responsive menus

## Project Structure

```
spider_solitaire/
├── project.godot              # Godot project config
├── scenes/                    # Godot scenes (.tscn)
│   ├── main.tscn              # Root game manager scene
│   ├── card.tscn              # Single card
│   ├── column.tscn            # Card column (drop target)
│   ├── stock.tscn             # Deal pile
│   ├── foundation.tscn        # Completed sequences area
│   └── ui/                    # Menu & HUD scenes
├── scripts/                   # GDScript source
│   ├── autoload/              # Singletons (GameState, Settings, Sound)
│   ├── card.gd                # Card rendering & input
│   ├── column.gd              # Column logic
│   ├── board.gd               # Game board & setup
│   ├── drag_system.gd         # Drag-and-drop handler
│   ├── rules_engine.gd        # Spider solitaire rules
│   ├── move_history.gd        # Undo stack
│   ├── main.gd                # Scene flow manager
│   └── ui/                    # UI controllers
└── assets/sounds/             # Sound effects (placeholders)
```

## How to Run

1. Open Godot 4.3+ Project Manager
2. Click **Import** and select `project.godot`
3. Press **F5** or click the play button

## How to Export

### iOS / iPadOS
1. Project → Export → Add Preset → iOS
2. Configure bundle ID, icons, and signing
3. Export Xcode project and build with Xcode

### Android
1. Project → Export → Add Preset → Android
2. Install Android build template if needed
3. Export APK or AAB

### Desktop
1. Project → Export → Add Preset → Windows / macOS / Linux
2. Export directly

## Game Rules

- Build descending sequences of cards (any suit)
- Complete **K→A same-suit sequences** to clear them
- Click the **Stock** to deal 1 card to each column (no empty columns allowed)
- Use **Undo** to reverse any move
- Try to win with the highest score!

## Controls

| Action | Mouse | Touch |
|--------|-------|-------|
| Select / Drag | Left-click & drag | Tap & drag |
| Deal | Click Stock | Tap Stock |
| Undo | Click Undo button | Tap Undo button |
| Pause | Click Pause button | Tap Pause button |
