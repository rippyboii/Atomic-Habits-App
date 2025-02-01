// Update StreakButton.swift with glow effects
import SwiftUI

struct StreakButton: View {
    let streak: AtomicStreak
    let onPress: () -> Void
    @State private var isAnimating = false
    
    private var shouldGlow: Bool {
        Date().timeIntervalSince(streak.lastPressed) < 86400 // 24 hours in seconds
    }
    
    var body: some View {
        Button(action: {
            onPress()
            triggerAnimation()
        }) {
            ZStack {
                // Glow effect
                if shouldGlow {
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: [.orange, .yellow, .orange]),
                                center: .center,
                                angle: .degrees(isAnimating ? 360 : 0)
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 8)
                        .opacity(0.7)
                        .animation(
                            Animation.linear(duration: 2).repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                
                // Main button
                VStack {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 60, height: 60)
                            .shadow(
                                color: shouldGlow ? .orange : .clear,
                                radius: shouldGlow ? 8 : 0
                            )
                        
                        Image(systemName: streak.icon)
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    Text(streak.name)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .frame(width: 60)
                    
                    Text("\(streak.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if shouldGlow {
                isAnimating = true
            }
        }
    }
    
    private func triggerAnimation() {
        isAnimating = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAnimating = true
        }
    }
}
