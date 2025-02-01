//
//  ProfileManager.swift
//  Atomic Habits
//

/*
This file defines the `ProfileManager` class, responsible for managing user profiles, including creation, deletion, renaming, and persistent storage.

- **Major Components**:
  - `profiles`: A published array of `Profile` objects representing user profiles.
  - **Persistent Storage**: Profiles are saved to and loaded from `profiles.json` in the app's document directory.
  - **Folder Management**: A dedicated folder is created for each profile in the document directory for storing profile-specific data.

- **Key Methods**:
  - `createProfile(named name: String)`: Creates a new profile, adds it to the list, creates a corresponding folder, and saves the updated list.
  - `deleteProfile(_ profile: Profile)`: Deletes a profile from the list, removes its folder, and saves the updated list.
  - `renameProfile(_ profile: Profile, to newName: String)`: Renames an existing profile's `name` and updates the stored data.
  - `loadProfiles()`: Loads the profiles from `profiles.json` at app launch.
  - `saveProfiles()`: Saves the profiles to `profiles.json` after any modification.

- **How It Interconnects**:
  - This class is shared across views using the `@EnvironmentObject` property wrapper.
  - `IntroView` references this object indirectly when transitioning to `ProfileListView`, where profiles are displayed or managed.
  - Line `@Published var profiles: [Profile] = []`: Allows `SwiftUI` views to update automatically when profiles change.
  - Transition Trigger: In `IntroView`, the `.environmentObject(ProfileManager())` at line 56 ensures the ProfileManager instance is accessible in `ProfileListView`.

This class serves as the backbone for profile data management and ensures persistence across app sessions.
*/

import Foundation
import SwiftUI

class ProfileManager: ObservableObject {
    @Published var profiles: [Profile] = []
    private let fileManager = FileManager.default
    
    init() {
        loadProfiles()
    }
    
    func createProfile(named name: String) {
        let newProfile = Profile(name: name)
        profiles.append(newProfile)
        createFolderForProfile(newProfile)
        saveProfiles()
    }
    
    func deleteProfile(_ profile: Profile) {
        profiles.removeAll { $0.id == profile.id }
        removeFolderForProfile(profile)
        saveProfiles()
    }
    
    /// Rename an existing profile’s `name` property.
    func renameProfile(_ profile: Profile, to newName: String) {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else { return }
        
        // Update the name
        profiles[index].name = newName
        
        // Optionally rename the folder on disk if you name folders by the profile’s name
        // Most apps keep folder names = profile IDs, so no rename needed on disk
        saveProfiles()
    }
    
    // MARK: - Folder creation/removal
    private func createFolderForProfile(_ profile: Profile) {
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let folderURL = docsURL.appendingPathComponent(profile.id)
        do {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating folder for profile \(profile.name):", error)
        }
    }
    
    private func removeFolderForProfile(_ profile: Profile) {
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let folderURL = docsURL.appendingPathComponent(profile.id)
        if fileManager.fileExists(atPath: folderURL.path) {
            do {
                try fileManager.removeItem(at: folderURL)
            } catch {
                print("Error removing folder for profile \(profile.name):", error)
            }
        }
    }
    
    // MARK: - Load & Save
    private func loadProfiles() {
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = docsURL.appendingPathComponent("profiles.json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            profiles = try JSONDecoder().decode([Profile].self, from: data)
            print("Profiles loaded successfully.")
        } catch {
            print("Error loading profiles (if none exists, this is normal):", error)
            profiles = [] // Start with an empty array if no profiles exist
        }
    }

    
    private func saveProfiles() {
        guard let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = docsURL.appendingPathComponent("profiles.json")
        
        do {
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: fileURL, options: .atomic)
            print("Profiles saved successfully.")
        } catch {
            print("Error saving profiles:", error)
        }
    }

}
