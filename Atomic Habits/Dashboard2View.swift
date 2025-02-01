//
//  Dashboard2View.swift
//  Atomic Habits
//
//  Created by Apeel Subedi on 27/01/2025.
//
import SwiftUI

struct Dashboard2View: View {
    var body: some View {
        ZStack {
            // Base color with material overlay
            Color.green
                .ignoresSafeArea()
                .overlay(
                    Material.thin
                        .opacity(0.7) // Adjust opacity as needed
                )
            
            VStack {
                Text("Dashboard 2")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
        }
        // Add drawing group for performance
        .drawingGroup(opaque: true, colorMode: .extendedLinear)
    }
}
