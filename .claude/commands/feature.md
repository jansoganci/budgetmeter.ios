# Create New Feature Module

Create a new feature module following the project's MVVM architecture.

## Arguments
- $ARGUMENTS: The name of the feature (e.g., "Profile", "Notifications")

## Instructions

If no feature name is provided, ask the user for one.

Create the following structure for the new feature:

```
Features/{Name}Feature/
├── ViewModel/
│   └── {Name}ViewModel.swift
└── View/
    └── {Name}View.swift
```

### ViewModel Template
```swift
import Foundation
import SwiftUI

@MainActor
final class {Name}ViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let persistenceService = PersistenceService.shared

    // MARK: - Initialization

    init() {
        // Initialize
    }

    // MARK: - Public Methods

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Load data
    }
}
```

### View Template
```swift
import SwiftUI

struct {Name}View: View {
    @StateObject private var viewModel = {Name}ViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("{Name}")
                .task {
                    await viewModel.loadData()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            // Main content
            Text("Hello from {Name}Feature")
        }
    }
}

#Preview {
    {Name}View()
}
```

Create both files with the templates above, replacing `{Name}` with the provided feature name.
