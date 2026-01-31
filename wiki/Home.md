# ClickerRemote Developer Wiki

Welcome to the ClickerRemote developer documentation. This wiki contains technical information for developers who want to build, modify, or contribute to the project.

## Quick Links

| Section | Description |
|---------|-------------|
| [[Getting-Started]] | Set up your development environment |
| [[Architecture]] | System design and component overview |
| [[Building]] | Build commands and distribution |
| [[API-Reference]] | Code structure and key classes |
| [[Contributing]] | How to contribute |
| [[Troubleshooting]] | Common issues and solutions |

## Project Overview

ClickerRemote is a presentation remote system consisting of two apps:

- **ClickerRemote** (iOS) — Remote control app for iPhone
- **ClickerRemoteReceiver** (macOS) — Menu bar app that receives commands

```mermaid
%%{init: {'theme': 'dark'}}%%
graph LR
    subgraph iPhone
        A[ClickerRemote]
    end
    subgraph Mac
        B[ClickerRemoteReceiver]
    end
    subgraph Presentation
        C[Keynote / PowerPoint / Slides]
    end

    A -->|MultipeerConnectivity| B
    B -->|CGEvent Keystrokes| C

    classDef default fill:#1a1a2e,stroke:#00ff41,color:#00ff41
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Language | Swift 5.9 |
| UI Framework | SwiftUI |
| Networking | MultipeerConnectivity |
| Build System | XcodeGen + xcodebuild |
| macOS Target | 14.0+ (Sonoma) |
| iOS Target | 18.0+ |

## Repository Structure

```
clicker/
├── project.yml          # XcodeGen configuration
├── Makefile             # Build automation
├── Shared/              # Shared code between apps
│   └── RemoteCommand.swift
├── MacApp/              # macOS menu bar app
├── iPhoneApp/           # iOS remote control app
├── docs/                # MkDocs documentation
├── wiki/                # GitHub Wiki source
└── Casks/               # Homebrew cask formula
```

## Distribution

| App | Distribution | Link |
|-----|--------------|------|
| ClickerRemoteReceiver | GitHub Releases (DMG) | [Releases](https://github.com/douinc/clicker/releases) |
| ClickerRemoteReceiver | Homebrew Cask | `brew tap douinc/clicker && brew install --cask clicker-remote-receiver` |
| ClickerRemote | App Store | [Coming Soon](https://apps.apple.com) |

## License

MIT License — see [LICENSE](https://github.com/douinc/clicker/blob/main/LICENSE)

---

*Maintained by [DOU Inc.](https://github.com/douinc)*
