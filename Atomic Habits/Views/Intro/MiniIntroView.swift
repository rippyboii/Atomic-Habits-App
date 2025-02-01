import SwiftUI

struct MiniIntroView: View {
    // These parameters should match exactly with what's expected
    let profile: Profile
    let animationNamespace: Namespace.ID
    
    @State private var blackOverlayOpacity: Double = 0
    @State private var blurAmount: CGFloat = 10
    @State private var textOpacity: Double = 1
    @State private var dashboardOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Properly initialized with required parameters
            RotatingDashboardsContainer(profile: profile, animationNamespace: animationNamespace)
                .opacity(dashboardOpacity)
            
            Color.black
                .opacity(blackOverlayOpacity)
                .ignoresSafeArea()
            
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.pink]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    Text("Atomic Habits")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                )
                .blur(radius: blurAmount)
                .opacity(textOpacity)
            }
        }
        .onAppear {
            runMiniIntroAnimation()
        }
    }
    
    private func runMiniIntroAnimation() {
        withAnimation(.easeInOut(duration: 2)) {
            blackOverlayOpacity = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 1)) {
                blurAmount = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(.easeInOut(duration: 2)) {
                        textOpacity = 0
                        blackOverlayOpacity = 0
                        dashboardOpacity = 1
                    }
                }
            }
        }
    }
}
