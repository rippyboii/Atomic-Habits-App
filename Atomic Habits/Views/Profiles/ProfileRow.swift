import SwiftUI

struct ProfileRow: View {
    let profile: Profile
    let animationNamespace: Namespace.ID
    
    var body: some View {
        ZStack {
            // A rounded rectangle background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue)
                // Connect to matchedGeometryEffect for the "zoom" animation
                .matchedGeometryEffect(id: profile.id, in: animationNamespace)
            
            // Display the profile's name in white text
            Text(profile.name)
                .foregroundColor(.white)
                .font(.headline)
        }
        .frame(height: 50) // A "button-like" height
        .padding(.vertical, 4)
    }
}
