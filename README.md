# SnapLingo

A gamified language-learning photo scavenger hunt app for the Swift Student Challenge 2026.

## Overview

SnapLingo turns vocabulary learning into an interactive photo scavenger hunt. Players are prompted to find real-world objects in their surroundings, snap a photo, and learn the word in their target language.

## Features

- **Photo Scavenger Hunt** — Find prompted objects within a 15-second timer
- **On-device object recognition** — FastViT-T8 CoreML model verifies what you photograph
- **Multiple environments** — Home, Food, Street, Zoo, and more
- **13 languages** — English, Spanish, French, German, Italian, Portuguese, Korean, Chinese, Arabic, Farsi, Japanese, Turkish, Polish
- **Scoring and streaks** — Points for speed and accuracy, streak bonuses for consecutive finds
- **Fully offline** — No network dependencies

## Project Structure

```
SnapLingo/
├── SnapLingoApp.swift
├── Models.swift
├── GameManager.swift
├── Extensions.swift
├── Data/
│   └── catalog.json
├── Services/
│   ├── CameraService.swift
│   ├── CatalogStore.swift
│   ├── ImageClassificationService.swift
│   ├── ObjectVerificationService.swift
│   └── VolumeButtonShutterService.swift
└── Views/
    ├── SetupView.swift
    ├── HomeMenuView.swift
    └── GameSessionView.swift
```

## Requirements

- Xcode 16+
- iOS 26 deployment target

## Building

1. Open `SnapLingo.xcodeproj` in Xcode
2. Select your target device
3. Build and run
