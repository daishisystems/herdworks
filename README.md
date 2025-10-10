# HerdWorks (iOS)

Minimal SwiftUI app with Clean Architecture scaffolding and multi-env setup (DEV/TEST/PROD).

## Local Setup
- Xcode 16+
- Schemes: **HerdWorks Dev**, **HerdWorks Test**, **HerdWorks Prod**
- Configs via `.xcconfig` in `Config/`
- Info.plist at `HerdWorks/Info.plist` with env-driven keys

## Firebase
- Projects: herdworks-dev / herdworks-test / herdworks-prod
- Auth: Email/Password enabled
- Plists in `Resources/`:
  - `GoogleService-Info-Dev.plist`
  - `GoogleService-Info-Test.plist`
  - `GoogleService-Info-Prod.plist`

## Build
- Select a scheme (e.g. HerdWorks Dev) → ⌘R
