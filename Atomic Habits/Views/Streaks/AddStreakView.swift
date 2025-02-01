// Update AddStreakView.swift with full icon selection
import SwiftUI

struct AddStreakView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var streakName = ""
    @State private var searchText = ""
    @State private var selectedIcon = "star.fill"
    
    let allIcons = [
        "flame.fill", "drop.fill", "leaf.fill", "bolt.fill", "heart.fill",
        "star.fill", "moon.fill", "sun.max.fill", "cloud.fill", "snowflake",
        "atom", "gamecontroller.fill", "book.fill", "graduationcap.fill",
        "figure.walk", "car.fill", "house.fill", "tag.fill", "bell.fill",
        "cart.fill", "creditcard.fill", "gift.fill", "wand.and.stars"
    ]
    
    let onAdd: (AtomicStreak) -> Void
    
    var filteredIcons: [String] {
        if searchText.isEmpty {
            return allIcons
        }
        return allIcons.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Search icons...", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 20) {
                        ForEach(filteredIcons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                ZStack {
                                    Circle()
                                        .fill(selectedIcon == icon ? Color.blue : Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .foregroundColor(selectedIcon == icon ? .white : .primary)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                TextField("Streak Name", text: $streakName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
            }
            .navigationTitle("New Streak")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Add") {
                    let newStreak = AtomicStreak(
                        name: streakName,
                        count: 0,
                        lastPressed: Date(),
                        icon: selectedIcon
                    )
                    onAdd(newStreak)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(streakName.isEmpty)
            )
        }
    }
}
