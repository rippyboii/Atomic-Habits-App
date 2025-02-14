import SwiftUI
import AVFoundation

struct RotatingDashboardsContainer: View {
    let profile: Profile
    let animationNamespace: Namespace.ID
    
    @State private var currentIndex = 0
    @State private var swipeDirection: SwipeDirection = .left
    @State private var audioPlayer: AVAudioPlayer?
    
    private let dashboards: [AnyView]
    private let swipeThreshold: CGFloat = 100
    
    enum SwipeDirection { case left, right }
    
    init(profile: Profile, animationNamespace: Namespace.ID) {
        self.profile = profile
        self.animationNamespace = animationNamespace
        
        // Simplified dashboards without drawingGroup
        self.dashboards = [
            AnyView(DashboardView(profile: profile, animationNamespace: animationNamespace)),
            AnyView(Dashboard1View()),
            AnyView(Dashboard2View()),
            AnyView(Dashboard3View()),
            AnyView(Dashboard4View(profile: profile))
        ]


    }
    
    var body: some View {
        ZStack {
            dashboards[currentIndex]
                .id(currentIndex)
                .transition(flipTransition)
        }
        .gesture(dragGesture)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                if value.translation.width < -100 {
                    swipeDirection = .left
                    withAnimation(.spring()) {
                        currentIndex = (currentIndex + 1) % dashboards.count
                    }
                } else if value.translation.width > 100 {
                    swipeDirection = .right
                    withAnimation(.spring()) {
                        currentIndex = (currentIndex - 1 + dashboards.count) % dashboards.count
                    }
                }
            }
    }
    
    private var flipTransition: AnyTransition {
        AnyTransition.asymmetric(
            insertion: .modifier(
                active: SimpleFlipModifier(angle: swipeDirection == .left ? 90 : -90),
                identity: SimpleFlipModifier(angle: 0)
            ),
            removal: .modifier(
                active: SimpleFlipModifier(angle: swipeDirection == .left ? -90 : 90),
                identity: SimpleFlipModifier(angle: 0)
            )
        )
    }
}

struct SimpleFlipModifier: ViewModifier {
    let angle: Double
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
    }
}
