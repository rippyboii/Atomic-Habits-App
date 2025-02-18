import SwiftUI

// MARK: - Data Model
struct QuickNote: Identifiable, Codable, Equatable {
    let id = UUID()
    var title: String
    var detail: String
    var deadline: Date
    var hasDeadline: Bool
}

struct AtomicStreak: Identifiable {
    let id = UUID()
    let name: String
    var count: Int
    var lastPressed: Date
    let icon: String
    var isGlowing: Bool = false
}

struct DashboardView: View {
    let profile: Profile
    let animationNamespace: Namespace.ID
    @State private var selectedTab: Int = 0
    @Environment(\.colorScheme) var colorScheme
    @State private var streaks: [AtomicStreak] = []
    @State private var showingAddStreak = false

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
                    actionButtons()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadQuickNotes() }
        .onChange(of: quickNotes) { _ in
            saveQuickNotes()
        }
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

    // MARK: - Streak Section
    private var streakView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Streaks")
                .font(.headline)
                .padding(.leading, 5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(streaks) { streak in
                        Text(streak.name) // You can replace this with your custom view for streaks
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
        .font(.subheadline)
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
            case 1: Text("Activity content here...").foregroundColor(.gray)
            case 2: Text("Settings content here...").foregroundColor(.gray)
            default: Text("Dashboard content here...").foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Quick Notes Content
    private var quickNotesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quick Notes")
                .font(.headline)
                .padding(.bottom, 5)
            
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
                    Text(formattedDeadline(date: note.deadline))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue.opacity(0.1)))
        .padding(.bottom, 5)
    }

    private func formattedDeadline(date: Date) -> String {
        let calendar = Calendar.current
        let today = Date()
        let daysDifference = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM"  // This will format it like "20 February"
        
        // Get the day of the week for the deadline date
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"  // Gets full day name like "Friday"
        let weekdayName = weekdayFormatter.string(from: date)
        
        // Adding the day suffix (e.g., 20th, 21st, etc.)
        let day = calendar.component(.day, from: date)
        
        
        let formattedDate = dateFormatter.string(from: date)
        if daysDifference < 7 {
            return "This \(weekdayName), \(formattedDate)"
        } else {
            return "\(formattedDate), \(weekdayName)"
        }
    }

    // MARK: - Action Buttons
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
        }
    }

    // MARK: - Save & Load Data
    private func saveQuickNotes() {
        // Get the documents directory for the current profile
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let profileFolderURL = docsURL.appendingPathComponent(profile.id)
        let fileURL = profileFolderURL.appendingPathComponent("quickNotes.json")
        
        do {
            let data = try JSONEncoder().encode(quickNotes)
            try data.write(to: fileURL)
            print("Quick notes saved to \(fileURL.path)")
        } catch {
            print("Error saving quick notes: \(error)")
        }
    }
    
    private func loadQuickNotes() {
        // Get the documents directory for the current profile
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let profileFolderURL = docsURL.appendingPathComponent(profile.id)
        let fileURL = profileFolderURL.appendingPathComponent("quickNotes.json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            let loadedNotes = try JSONDecoder().decode([QuickNote].self, from: data)
            quickNotes = loadedNotes
            print("Quick notes loaded from \(fileURL.path)")
        } catch {
            print("Error loading quick notes: \(error)")
        }
    }
}
