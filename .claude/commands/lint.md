# Run SwiftLint

Run SwiftLint to check code style and report any violations.

## Instructions

1. Check if SwiftLint is installed
2. If installed, run it on the project
3. Report violations grouped by severity (error, warning)
4. Suggest fixes for common issues

```bash
# Check if SwiftLint is installed
if command -v swiftlint &> /dev/null; then
    cd /Users/jans./Downloads/Projelerim/budgetmeter.ios && swiftlint lint --reporter emoji 2>&1 | head -100
else
    echo "SwiftLint is not installed. Install with: brew install swiftlint"
fi
```

If SwiftLint is not installed, provide installation instructions:
- `brew install swiftlint`

Summarize the linting results concisely.
