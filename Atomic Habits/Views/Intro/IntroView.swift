import SwiftUI

struct IntroView: View {
    // MARK: - State Variables

    @EnvironmentObject var profileManager: ProfileManager  // <-- NEW: Access shared user profile data across views.

    @State private var blurAmount: CGFloat = 10  // Controls the blur effect on the main title.
    @State private var typedSubtext: String = ""  // Tracks the currently displayed subtext during typing animation.
    private let fullSubtext = "A transition from the book"  // The complete subtext to type out.

    @State private var showButton = false  // Determines when to display the "Let's Begin" button.
    @State private var zoomIn = false  // Triggers the Netflix-style zoom animation for the title.
    @State private var showColoredOverlay = false  // Toggles the display of the pink overlay.
    @State private var overlayOpacity: Double = 0  // Controls the opacity of the pink overlay.

    @State private var showProfileListView = false  // Controls navigation to ProfileListView after the intro.

    var body: some View {
        ZStack {
            // Background: always black unless the pink overlay is active.
            Color.black.ignoresSafeArea()

            // If the overlay is active, show a pink color with fading effects.
            if showColoredOverlay {
                Color.pink
                    .opacity(overlayOpacity)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Main content layout
            VStack(spacing: 4) {
                Spacer()

                // 1) Main Title: Displays "Atomic Habits" with a gradient and blur animation.
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
                    .blur(radius: blurAmount)  // Starts blurred, animates to unblur.
                    .scaleEffect(zoomIn ? 20 : 1)  // Netflix-style zoom effect.
                    .opacity(zoomIn ? 0 : 1)  // Fades out during zoom.
                    .animation(.easeInOut(duration: 1.0), value: zoomIn)
                }

                // 2) Subtext: Displays the typed subtext below the title after animations.
                if !zoomIn {
                    Text(typedSubtext)
                        .font(.custom("september", size: 16))
                        .italic()
                        .foregroundColor(.gray)
                        .transition(.opacity)
                }

                Spacer()

                // 3) Button: "Let's Begin" appears after the subtext is fully typed.
                if showButton && !zoomIn {
                    Button {
                        // Starts the zoom sequence and transitions to the next view.
                        zoomSequence()
                    } label: {
                        Text("Let's Begin")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 30)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .transition(.opacity)
                }

                Spacer()
            }
        }
        // Full-screen cover to navigate to ProfileListView after intro animations.
        .fullScreenCover(isPresented: $showProfileListView) {
            ProfileListView()
                .environmentObject(ProfileManager())  // Pass environment object to the next view.
        }
        .onAppear {
            startIntroAnimations()  // Triggers the intro animations when the view appears.
        }
    }

    // MARK: - Step 1: Unblur Title and Type Subtext
    private func startIntroAnimations() {
        // Gradually unblur the title over 1 second.
        withAnimation(.easeInOut(duration: 1)) {
            blurAmount = 0
        }

        // Start typing the subtext after the unblur animation completes.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            typeSubtext()
        }
    }

    // MARK: - Typing Animation for Subtext
    private func typeSubtext() {
        typedSubtext = ""  // Ensure the subtext starts empty.

        // Animate typing of each character over ~2 seconds.
        let totalDuration: Double = 2.0
        let characters = Array(fullSubtext)  // Convert the subtext to a character array.
        let charDelay = totalDuration / Double(characters.count)  // Delay per character.

        for (index, char) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + (Double(index) * charDelay)) {
                typedSubtext.append(char)  // Append each character to the subtext.

                // Show the button once the subtext is fully typed.
                if index == characters.count - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            showButton = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Netflix-Style Zoom and Overlay Animation
    private func zoomSequence() {
        // 1) Trigger zoom-in animation for the title.
        withAnimation {
            zoomIn = true
        }

        // 2) Display and animate the pink overlay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            showColoredOverlay = true

            // Fade the overlay in quickly.
            withAnimation {
                overlayOpacity = 0.6
            }

            // After 1 second, fade the overlay out and transition to ProfileListView.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    overlayOpacity = 0
                }

                // Remove overlay and navigate to ProfileListView.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showColoredOverlay = false

                    // Navigate to ProfileListView.
                    showProfileListView = true
                }
            }
        }
    }
}

// MARK: - Preview
struct IntroView_Previews: PreviewProvider {
    static var previews: some View {
        IntroView()
    }
}
