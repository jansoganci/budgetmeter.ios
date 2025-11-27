# Clean Build

Clean the Xcode build folder and derived data for a fresh build.

## Instructions

1. Clean the build using xcodebuild
2. Optionally remove DerivedData for this project
3. Confirm the clean was successful

```bash
xcodebuild -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios clean 2>&1 | tail -20
```

Report when cleaning is complete.
