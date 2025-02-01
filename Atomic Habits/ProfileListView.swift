import SwiftUI

struct ProfileListView: View {
    @EnvironmentObject var profileManager: ProfileManager

    // Keep track of which profile is selected for transition
    @State private var selectedProfile: Profile? = nil
    
    // Namespace for matchedGeometryEffect animations
    @Namespace private var animationNamespace
    
    var body: some View {
        VStack {
            if profileManager.profiles.isEmpty {
                Text("No profiles yet. Create one below!")
                    .foregroundColor(.gray)
                    .padding()
            }

            // The list of profiles
            List {
                ForEach(profileManager.profiles) { profile in
                    ProfileRow(profile: profile, animationNamespace: animationNamespace)
                        .onTapGesture {
                            // Trigger zoom-in animation and move to MiniIntroView
                            withAnimation(.easeInOut(duration: 0.5)) {
                                selectedProfile = profile
                            }
                        }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let p = profileManager.profiles[index]
                        profileManager.deleteProfile(p)
                    }
                }
            }
            
            // Button to add a new profile
            Button(action: {
                // Existing logic to create a new profile
            }) {
                Text("Add Profile")
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding(.bottom)
        }
        // Use fullScreenCover to avoid back navigation
        .fullScreenCover(item: $selectedProfile) { profile in
            MiniIntroView(profile: profile, animationNamespace: animationNamespace)
                .environmentObject(profileManager)
        }
    }
}
