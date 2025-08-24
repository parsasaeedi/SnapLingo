# SnapLingo 📸🎯

A gamified language-learning photo scavenger hunt app for the Swift Student Challenge 2026.

## Overview

SnapLingo transforms language learning into an engaging photo scavenger hunt experience. Users are prompted to find specific objects in their environment, take photos, and learn vocabulary through interactive gameplay.

## Features

### 🎮 Core Gameplay
- **Photo Scavenger Hunt**: Find objects based on prompts within a 15-second timer
- **Smart Scoring**: Points awarded based on speed and accuracy
- **Streak System**: Build momentum with consecutive successful finds
- **Progress Tracking**: Visual progress bar and session statistics

### 🏠 Environments
- **Home Environment**: 35+ household items including kitchen, bathroom, and living room objects
- **Future Environments**: Park, Downtown, Kitchen (coming soon)

### 🎯 Game Mechanics
- **15-second Timer**: Color-coded countdown (black → orange → red)
- **Perfect Bonus**: +50 points for finding items within first 5 seconds
- **Haptic Feedback**: Tactile cues at 5, 3, and 1 second marks
- **Spaced Repetition**: Missed items reappear in future sessions

### 🎨 UI/UX Design
- **Liquid Glass Aesthetic**: Modern, translucent interface elements
- **Duolingo-Inspired**: Familiar, engaging design patterns
- **Responsive Layout**: Optimized for iPhone 15 Pro Max
- **Accessibility**: VoiceOver support and dynamic type

## Technical Architecture

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: On-device data persistence
- **Vision Framework**: Camera pipeline and OCR (future)
- **Core ML**: FastViT-T8 for object verification (future)
- **Foundation Models**: On-device LLM for hints and recaps (future)

### Data Models
- `GameSession`: Tracks individual gameplay sessions
- `GameItem`: Represents objects to find with metadata
- `UserProgress`: Persistent user statistics and streaks
- `Environment`: Defines available settings and their objects

### Key Components
- `GameManager`: Central game logic and state management
- `CameraService`: Camera permissions and capture handling
- `SetupView`: Language selection interface
- `HomeMenuView`: Environment selection with grid layout
- `GameSessionView`: Main gameplay interface with camera overlay

## Installation & Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ (target iOS 26)
- iPhone 15 Pro Max (for testing)

### Build Instructions
1. Clone the repository
2. Open `SnapLingo.xcodeproj` in Xcode
3. Select your target device (iPhone 15 Pro Max recommended)
4. Build and run the project

### Camera Permissions
The app requires camera access for the photo scavenger hunt functionality. Permissions are requested automatically on first launch.

## Game Flow

### 1. Setup Phase
- Language selection (inspired by iOS Language setup)
- 10 supported languages including English, Spanish, French, etc.

### 2. Home Menu
- Environment selection with 2-column grid layout
- Shows available environments and item counts
- Preview of upcoming environments

### 3. Gameplay Session
- 12 random objects per session (3-minute demo-friendly)
- 15-second timer per object
- Real-time scoring and feedback
- Streak tracking and visual indicators

### 4. Session Completion
- Final score and statistics
- LLM-generated recap of performance
- Return to home menu

## Scoring System

### Point Calculation
- **Base Points**: 50 points per found object
- **Perfect Bonus**: +50 points for finding within first 5 seconds
- **Time Bonus**: Up to 50 additional points based on speed
- **Maximum per Object**: 150 points

### Timer Behavior
- **15-10 seconds**: Black color (normal)
- **10-5 seconds**: Orange color (warning)
- **5-0 seconds**: Red color (urgent)
- **Haptic Feedback**: Medium impact at 5, 3, and 1 seconds

## Future Enhancements

### Planned Features
- **Real Object Detection**: Vision + Core ML integration
- **Additional Environments**: Park, Downtown, Kitchen
- **Multi-language Support**: Full localization
- **Social Features**: Leaderboards and sharing
- **Advanced Analytics**: Detailed learning insights

### Technical Roadmap
- **Vision Pipeline**: Real-time object detection
- **Core ML Models**: FastViT-T8 integration
- **Foundation Models**: On-device LLM for hints
- **Performance Optimization**: Reduced app size and improved speed

## Project Structure

```
SnapLingo/
├── SnapLingoApp.swift          # Main app entry point
├── Models.swift                # Data models and structures
├── GameManager.swift           # Game logic and state management
├── ContentView.swift           # Legacy view (placeholder)
├── Views/
│   ├── SetupView.swift         # Language selection
│   ├── HomeMenuView.swift      # Environment selection
│   └── GameSessionView.swift   # Main gameplay interface
├── Services/
│   └── CameraService.swift     # Camera handling and permissions
└── Assets.xcassets/            # App icons and resources
```

## Swift Student Challenge 2026

This project is designed specifically for the Swift Student Challenge 2026 with the following considerations:

### Requirements Met
- ✅ **Offline Functionality**: No network dependencies
- ✅ **Size Limit**: Under 25MB .zip file
- ✅ **English Content**: Primary language support
- ✅ **Swift Playgrounds Compatible**: Runs in Xcode and Swift Playgrounds
- ✅ **iOS 26 Target**: Latest platform features

### Demo-Friendly Features
- **3-minute Sessions**: Perfect for live demonstrations
- **Immediate Feedback**: Visual and haptic responses
- **Engaging UI**: Modern design that showcases SwiftUI capabilities
- **Educational Value**: Clear learning objectives and progress tracking

## Contributing

This is a Swift Student Challenge submission. For educational purposes, feel free to explore the code and learn from the implementation patterns.

## License

This project is created for educational purposes as part of the Swift Student Challenge 2026.

---

**Built with ❤️ using SwiftUI and SwiftData**
