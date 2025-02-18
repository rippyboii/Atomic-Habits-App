import SwiftUI

// MARK: - Data Model
struct AtomicStreak: Identifiable {
    let id = UUID()
    let name: String
    var count: Int
    var lastPressed: Date
    let icon: String
    var isGlowing: Bool = false
}

// To reuse Dashboard4View's Transaction type.
typealias Transaction = Dashboard4View.Transaction

// MARK: - Main View
struct DashboardView: View {
    let profile: Profile
    let animationNamespace: Namespace.ID
    @State private var selectedTab: Int = 0
    @Environment(\.colorScheme) var colorScheme
    @State private var streaks: [AtomicStreak] = []
    @State private var showingAddStreak = false

    // MARK: - Shared Data (Simulated from Dashboard4View)
    @State private var quickNotes: [QuickNote] = []  // Changed to a struct for note details

    @State private var showingAddNote = false
    @State private var newNote = QuickNote(title: "", detail: "", deadline: Date(), hasDeadline: false)

    // MARK: - Body
    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color.white)
                .ignoresSafeArea()
                .overlay(Material.regular.opacity(0.7))
            
            ScrollView {
                VStack(spacing: 30) {
                    headerView
                    streakView
                    tabView
                    contentView
                    actionButtons()  // Corrected here
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddNote) {
            VStack {
                Text("Add New Note")
                    .font(.title)
                    .padding()
                
                TextField("Title", text: $newNote.title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Detail", text: $newNote.detail)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Toggle("Has Deadline", isOn: $newNote.hasDeadline)
                    .padding()
                
                if newNote.hasDeadline {
                    DatePicker("Deadline", selection: $newNote.deadline, displayedComponents: .date)
                        .padding()
                }
                
                Button("Save") {
                    quickNotes.append(newNote)
                    newNote = QuickNote(title: "", detail: "", deadline: Date(), hasDeadline: false)
                    showingAddNote = false
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }
    
    // MARK: - Header Section
    private var headerView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .matchedGeometryEffect(id: profile.id, in: animationNamespace)
            
            VStack {
                Text("Welcome")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                Text(profile.name)
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
            }
        }
        .frame(height: 150)
        .shadow(radius: 10)
    }

    // MARK: - Streaks Section
    private var streakView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Streaks")
                .font(.headline)
                .padding(.leading, 5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(streaks) { streak in
                        StreakButton(streak: streak) {
                            pressStreak(streak)
                        }
                    }
                    addStreakButton
                }
                .padding(.horizontal, 15)
            }
        }
        .frame(height: 120)
    }
    
    private var addStreakButton: some View {
        Button(action: { showingAddStreak = true }) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: "plus")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
    }
    
    // MARK: - Tab Section
    private var tabView: some View {
        HStack {
            tabButton(title: "Quick Notes", tag: 0)
            tabButton(title: "Activity", tag: 1)
            tabButton(title: "Settings", tag: 2)
        }
        .font(.subheadline)  // Adjust font size here
        .background(Capsule().fill(Color.gray.opacity(0.2)))
        .padding(.horizontal)
    }
    
    private func tabButton(title: String, tag: Int) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = tag
            }
        }) {
            Text(title)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    Capsule().fill(selectedTab == tag ? Color.blue : Color.clear)
                )
        }
        .foregroundColor(selectedTab == tag ? .white : .primary)
    }
    
    // MARK: - Content Section
    private var contentView: some View {
        VStack {
            switch selectedTab {
            case 0: quickNotesContent
            case 1: activityContent
            case 2: settingsContent
            default: Text("Dashboard content here...")
                        .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Tab Contents
    private var quickNotesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quick Notes")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Split the ForEach into a function to reduce complexity
            ForEach(quickNotes) { note in
                quickNoteRow(note: note)
            }
        }
        .padding(15)
    }

    private func quickNoteRow(note: QuickNote) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(note.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(note.detail)
                    .font(.body)
                    .padding(.top, 5)
                
                if note.hasDeadline {
                    Text("Deadline: \(formattedDate(note.deadline))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if selectedTab == 1 {  // If in edit mode
                Button(action: {
                    removeNote(note)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.title)
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.1)))
        .padding(.bottom, 5)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func removeNote(_ note: QuickNote) {
        if let index = quickNotes.firstIndex(where: { $0.id == note.id }) {
            quickNotes.remove(at: index)
        }
    }
    
    private var activityContent: some View {
        Text("Activity content here...")
            .foregroundColor(.gray)
    }
    
    private var settingsContent: some View {
        Text("Settings content here...")
            .foregroundColor(.gray)
    }
    
    // MARK: - Helper Views
    private func actionButtons() -> some View {
        HStack(spacing: 20) {
            Button(action: { showingAddNote = true }) {
                VStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text("Add Note")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                )
            }

            Button(action: {}) {
                VStack {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                    Text("Edit")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                )
            }
        }
    }
    
    // MARK: - Streak Logic
    private func pressStreak(_ streak: AtomicStreak) {
        if let index = streaks.firstIndex(where: { $0.id == streak.id }) {
            streaks[index].lastPressed = Date()
            streaks[index].count += 1
            // Trigger glow animation
            DispatchQueue.main.async {
                streaks[index].isGlowing = true
            }
            // Auto-disable glow after 24 hours
            DispatchQueue.main.asyncAfter(deadline: .now() + 86400) {
                streaks[index].isGlowing = false
            }
        }
    }
}

// QuickNote structure
struct QuickNote: Identifiable {
    let id = UUID()
    var title: String
    var detail: String
    var deadline: Date
    var hasDeadline: Bool
}
