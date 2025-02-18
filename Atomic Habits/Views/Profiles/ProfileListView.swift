import SwiftUI

struct ProfileListView: View {
    @EnvironmentObject var profileManager: ProfileManager
    
    @State private var selectedProfile: Profile? = nil
    @State private var showCreateProfileSheet: Bool = false
    @State private var newProfileName: String = ""
    @State private var renameProfile: Profile? = nil
    @State private var renameText: String = ""
    
    // Variables to handle password protection
    @State private var isPasswordPromptPresented: Bool = false
    @State private var passwordInput: String = ""
    @State private var profileToDelete: Profile? = nil
    @State private var showErrorMessage: Bool = false
    
    @Namespace private var animationNamespace
    
    var body: some View {
        VStack {
            if profileManager.profiles.isEmpty {
                Text("No profiles yet. Create one below!")
                    .foregroundColor(.gray)
                    .padding()
            }

            List {
                ForEach(profileManager.profiles) { profile in
                    ProfileRow(profile: profile, animationNamespace: animationNamespace)
                        .onTapGesture {
                            // Trigger zoom-in animation and move to MiniIntroView (Profile Dashboard)
                            withAnimation(.easeInOut(duration: 0.5)) {
                                selectedProfile = profile
                            }
                        }
                        .swipeActions {  // Replace delete with rename on swipe left
                            Button(action: {
                                self.renameProfile = profile
                            }) {
                                Text("Rename")
                                Image(systemName: "pencil")
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button(action: {
                                // When the delete action is triggered, show the password prompt
                                self.profileToDelete = profile
                                self.isPasswordPromptPresented = true
                            }) {
                                Text("Delete Profile")
                                Image(systemName: "trash")
                            }
                        }
                }
            }
            
            // Add Profile Button
            Button(action: {
                showCreateProfileSheet = true
            }) {
                Text("Add Profile")
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.bottom)
            
            // Navigation title
            .navigationTitle("Select a Profile")
        }
        
        // MARK: - Sheet #1: Create a New Profile
        .sheet(isPresented: $showCreateProfileSheet) {
            VStack {
                Text("Create New Profile")
                    .font(.title3)
                    .padding(.bottom)
                
                TextField("Profile Name", text: $newProfileName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                HStack {
                    Button("Cancel") {
                        showCreateProfileSheet = false
                        newProfileName = "" // Reset the name field
                    }
                    Spacer()
                    Button("Save") {
                        let trimmed = newProfileName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            profileManager.createProfile(named: trimmed)  // Create the profile
                        }
                        showCreateProfileSheet = false
                        newProfileName = "" // Reset after saving
                    }
                }
                .padding()
            }
            .presentationDetents([.fraction(0.3)]) // Optional: controls the sheet size
        }
        
        // MARK: - Password Prompt for Deleting Profile
        .alert(isPresented: $isPasswordPromptPresented) {
            Alert(
                title: Text("Enter Password"),
                message: Text("Please enter the password to delete this profile."),
                primaryButton: .default(Text("Delete"), action: {
                    // Check if the entered password matches
                    if passwordInput == "samsungs6edge" {
                        if let profileToDelete = profileToDelete {
                            profileManager.deleteProfile(profileToDelete)
                        }
                    } else {
                        showErrorMessage = true
                    }
                    // Reset password input and dismiss the alert
                    passwordInput = ""
                    isPasswordPromptPresented = false
                }),
                secondaryButton: .cancel({
                    // Just dismiss the password prompt without doing anything
                    passwordInput = ""
                    isPasswordPromptPresented = false
                })
            )
        }
        
        // MARK: - Show Error Message
        .alert(isPresented: $showErrorMessage) {
            Alert(
                title: Text("Incorrect Password"),
                message: Text("The password you entered is incorrect. Please try again."),
                dismissButton: .default(Text("OK"))
            )
        }
        
        // MARK: - Sheet #2: Rename Existing Profile
        .sheet(item: $renameProfile) { profileToRename in
            VStack {
                Text("Rename Profile")
                    .font(.title3)
                    .padding(.bottom)
                
                TextField("New name", text: $renameText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                HStack {
                    Button("Cancel") {
                        renameProfile = nil
                    }
                    Spacer()
                    Button("Save") {
                        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            profileManager.renameProfile(profileToRename, to: trimmed) // Rename the profile
                        }
                        renameProfile = nil
                    }
                }
                .padding()
            }
            .presentationDetents([.fraction(0.3)]) // Optional: controls the sheet size
        }
        
        // Use fullScreenCover to navigate to the profile dashboard
        .fullScreenCover(item: $selectedProfile) { profile in
            MiniIntroView(profile: profile, animationNamespace: animationNamespace)
                .environmentObject(profileManager)
        }
    }
}
