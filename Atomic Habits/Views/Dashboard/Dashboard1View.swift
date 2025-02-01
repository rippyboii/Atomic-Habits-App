//
//  Dashboard1View.swift
//  Atomic Habits
//
//  Created by Apeel Subedi on 27/01/2025.
//

import SwiftUI

struct Dashboard1View: View {
    var body: some View {
        ZStack {
            // Base color with material overlay
            Color.red
                .ignoresSafeArea()
                .overlay(
                    Material.regular
                        .opacity(0.7) // Adjust opacity as needed
                )
            
            VStack {
                Text("Dashboard 1")
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }
        }
        // Add drawing group for performance
        .drawingGroup(opaque: true, colorMode: .extendedLinear)
    }
}
