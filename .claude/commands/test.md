# Run Tests

Run all unit tests for the BudgetMeter iOS project.

## Instructions

1. Run the test suite using xcodebuild
2. Parse the output for test results
3. Report: total tests, passed, failed
4. If any tests fail, show the failure details

```bash
xcodebuild test -project budgetmeter.ios.xcodeproj -scheme budgetmeter.ios -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:budgetmeter.iosTests 2>&1 | grep -E "(Test Case|passed|failed|error:)" | tail -100
```

Provide a clear summary of test results.
