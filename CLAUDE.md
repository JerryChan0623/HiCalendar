# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HiCalendar is a "Cute Calendar AI" iOS app built with SwiftUI that allows users to manage events through natural language AI interactions. The app features a playful, sarcastic AI personality that provides witty commentary while helping users create, modify, and query calendar events. The design follows Neobrutalism aesthetic with high contrast colors and bold borders.

## Development Commands

### Building and Testing
```bash
# Open project in Xcode
open HiCalendar.xcodeproj

# Build from command line (if needed)
xcodebuild -project HiCalendar.xcodeproj -scheme HiCalendar build

# Run tests
xcodebuild test -project HiCalendar.xcodeproj -scheme HiCalendar -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Project Structure
- `HiCalendar/` - Main app source code
- `HiCalendarTests/` - Unit tests  
- `HiCalendarUITests/` - UI tests
- `Docs/` - Design documentation and HTML demos
- `PRD.md` - Product requirements document (in Chinese)

## Code Architecture

### Core Data Models (`Models.swift`)
- **User**: User profile with email, timezone, sarcasm level (0-3), and push notification preferences
- **Event**: Calendar events with optional start/end times and details
- **AIResponse**: AI interaction results with conclusion, sarcasm, suggestions, and action types
- **CalendarDay**: Date representation with associated events for calendar views

### Data Management (`EventStorageManager.swift`)
- Singleton class using UserDefaults for local event persistence
- ObservableObject for SwiftUI reactive updates
- Provides CRUD operations for events with date-based filtering
- Loads sample data if no saved events exist

### Design System (`DesignTokens.swift`)
- **Neobrutalism style**: High contrast colors, bold borders, no shadows
- **Dark mode support**: Dynamic colors that adapt to system appearance
- **Brand colors**: Bright yellow (#FFFF00), electric blue (#00BFFF), neon green, warning red
- **Typography**: Bold system fonts with heavy weights for headers
- **Layout**: Consistent spacing (4-32pt), border widths (2-5pt), button heights (44pt)

### UI Components Structure
- `Views/` folder contains all SwiftUI views:
  - `CalendarView.swift` - Month/week/day calendar display
  - `EventEditView.swift` - Event creation and editing with auto-save
  - `EventListView.swift` - List of events with search
  - `HomeView.swift` - AI chat interface and today's summary
  - `MainCalendarAIView.swift` - Main calendar with AI features
  - `SettingsView.swift` - User preferences and sarcasm level

### Key Files
- `ContentView.swift` - Root view and navigation
- `HiCalendarApp.swift` - App entry point
- `UIComponents.swift` - Reusable Neobrutalism UI components including custom alerts and sheet headers
- `Item.swift` - Core Data model (if using Core Data)

### Custom Neobrutalism UI Components (`UIComponents.swift`)
- **NeobrutalismAlert**: Custom alert dialog with high contrast design and bold borders
- **NeobrutalismSheetHeader**: Custom sheet drag indicator replacing system defaults
- **AlertButtonStyle**: Styled buttons for custom alerts (normal/destructive variants)
- **CapsuleButtonStyle**: Main button style with thick borders and bold colors
- **GhostButtonStyle**: Secondary button style with transparent background

## Development Guidelines

### Design Consistency
- Follow Neobrutalism design tokens in `DesignTokens.swift`
- Use `BrandColor`, `BrandFont`, `BrandSpacing` enums for consistency
- Apply `.neobrutalStyle()` modifier for consistent borders
- Maintain high contrast and bold visual hierarchy

### Event Management
- Always use `EventStorageManager.shared` for event operations
- Events should have meaningful titles and optional time ranges
- Use sample data for development/testing via `Event.sampleEvents`

### AI Integration
- AI responses should include conclusion, sarcasm, and actionable suggestions
- Sarcasm levels: 0 (gentle) to 3 (heavy sarcasm)
- Action types: create, query, modify, delete, conflict, unknown

### Localization
- UI text is primarily in Chinese as this is a Chinese market product
- Date/time formatting should respect user's timezone preferences
- Sample data includes Chinese event titles with emoji

### Testing
- Use sample data from `Models.swift` for consistent testing
- Test both light and dark mode appearances
- Verify event CRUD operations through `EventStorageManager`

## Technical Notes

- **iOS Deployment Target**: 18.5+
- **Swift Version**: 5.0
- **Architecture**: MVVM with ObservableObject
- **Data Persistence**: UserDefaults (simple local storage)
- **Dependencies**: None (pure SwiftUI/Foundation)
- **Bundle ID**: com.example.HiCalendar

The app is designed to be a delightful, personality-driven calendar experience that makes event management both functional and entertaining through AI-powered natural language interactions.
- 中文回复我