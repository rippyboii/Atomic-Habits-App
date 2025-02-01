//
//  Atomic_HabitsApp.swift
//  Atomic Habits
//
//  Created by Apeel Subedi on 20/01/2025.
//

/*
This file defines the entry point of the Atomic Habits app, configuring the main view and shared state management.

- **Major Components**:
  - **`ProfileManager`**:
    - A single instance of `ProfileManager` is created as a `@StateObject` (line 8) to manage the app's profiles.
    - This instance is shared across the app using `.environmentObject`, ensuring consistent data access in all dependent views.

- **Key Features**:
  1. **Main Scene**:
     - The `WindowGroup` (line 11) represents the app's main UI window, starting with `IntroView`.
  2. **Environment Object**:
     - The `.environmentObject(profileManager)` (line 13) makes the `ProfileManager` instance available to `IntroView` and its child views, enabling centralized state management for profiles.

- **How It Interconnects**:
  - **`IntroView`**:
    - This is the app's initial view, as defined in the `WindowGroup` (line 12).
    - `IntroView` uses the shared `ProfileManager` for managing profile-related actions and transitions to `ProfileListView` after its animations.
  - **Global Access**:
    - The use of `.environmentObject` ensures that views like `ProfileListView` and `DashboardView` can access the shared `ProfileManager` instance seamlessly.

This file sets up the app's foundational structure, enabling the use of SwiftUI's environment and state management for a smooth and interconnected user experience.
*/

import SwiftUI

@main
struct Atomic_HabitsApp: App {
    // 1) Create a single ProfileManager as a StateObject
    @StateObject private var profileManager = ProfileManager()
    
    var body: some Scene {
        WindowGroup {
            // 2) Pass it to IntroView, or use environmentObject if you want it everywhere
            IntroView()
                .environmentObject(profileManager)
        }
    }
}
