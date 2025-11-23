# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LifeCultivation (人生修行) is a native iOS habit-tracking application built with SwiftUI and SwiftData. The app helps users cultivate healthy lifestyle habits through a gamified scoring system and data visualization.

## Technology Stack

- **Language**: Swift
- **UI Framework**: SwiftUI (iOS 26+)
- **Data Persistence**: SwiftData
- **Charts**: SwiftUI Charts framework
- **Architecture**: MVVM pattern
- **Development**: Xcode project (no package managers)

## Build Commands

```bash
# Build the app
xcodebuild -scheme LifeCultivation -configuration Debug build

# Run tests
xcodebuild test -scheme LifeCultivation

# Create archive for distribution
xcodebuild archive -scheme LifeCultivation -archivePath LifeCultivation.xcarchive

# Clean build folder
xcodebuild clean -scheme LifeCultivation
```

## Architecture & Key Components

### Data Models
- **DailyRecord**: Main data model storing daily habit scores and timestamps
- **AppSettings**: User preferences for goals (wake time, bed time, screen time limits)

### Main Views Structure
- **ContentView.swift**: Tab navigation controller (Today, History, Settings)
- **TodayView.swift**: Daily scoring interface with real-time feedback
- **HistoryView.swift**: Data visualization with SwiftUI Charts
- **SettingsView.swift**: User preferences and data management

### Scoring System
The app uses a 0-10 point daily system:
- **Diet (3 points)**: Based on meal regularity and food choices
- **Sleep (3 points)**: Wake-up and bedtime compliance
- **Screen Time (4 points)**: Tiered scoring against user-defined limits
- **Exercise**: Weekly reward points (not part of daily score)

### UI Components
Views are organized by functionality in the `Views/` directory:
- ScoreCardView: Overall score display with ratings
- [Habit]SectionView: Individual habit tracking components
- Each section handles its own state management and user interactions

## Development Requirements

- **Minimum iOS**: 26.0 (due to SwiftData dependency)
- **Xcode**: 16.1.1 or later
- **Device**: iPhone deployment target
- **Language**: Primary interface in Chinese with English code comments

## Key Implementation Details

### SwiftData Setup
App uses SwiftData for local persistence with model containers configured in `LifeCultivationApp.swift`. Models are defined in `Models.swift` with proper relationships and attributes.

### MVVM Pattern
- Views handle UI presentation and user interactions
- Models contain business logic and data structures
- No separate ViewModels - simplified MVVM using SwiftUI's reactive patterns

### Color Scheme
Primary accent color is orange (#FF9500) with system colors for consistency. Rating system uses color-coded feedback for performance levels.

### Data Visualization
History view uses SwiftUI Charts framework with configurable time ranges (week, month, quarter, half-year, year) and interactive data filtering.

## Product Documentation

See `spec/prd.md` for comprehensive product requirements, feature specifications, and development roadmap. The PRD includes detailed user stories, technical requirements, and version planning.

## Testing

Unit and UI test templates exist but need expansion. Current test coverage is minimal - focus on testing:
- Score calculation logic
- Data model persistence
- UI state management
- Chart data accuracy