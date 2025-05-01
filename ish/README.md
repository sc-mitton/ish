# ish

A SwiftUI-based iOS/macOS application.

## Project Structure

The project is organized following clean architecture principles and Swift best practices:

```
ish/
├── Sources/
│   ├── Views/         # SwiftUI views and view modifiers
│   ├── Models/        # Data models and business logic
│   ├── ViewModels/    # View models and state management
│   ├── Services/      # Network, storage, and other services
│   ├── Utils/         # Utility functions and helpers
│   └── Extensions/    # Swift extensions
├── Assets.xcassets/   # Image assets and resources
├── ishTests/         # Unit tests
└── ishUITests/       # UI tests
```

## Getting Started

1. Open `ish.xcodeproj` in Xcode
2. Build and run the project

## Development Guidelines

- Follow SwiftUI best practices
- Use MVVM architecture pattern
- Keep views small and focused
- Write unit tests for business logic
- Document public interfaces
