# List Simulators

List available iOS simulators for testing.

## Instructions

Show available iOS simulators that can be used for building and testing.

```bash
xcrun simctl list devices available | grep -E "(iPhone|iPad)" | head -20
```

Present the list in a clean format showing device names.
