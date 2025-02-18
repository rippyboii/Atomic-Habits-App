import SwiftUI

// Define the QuickNote struct
struct QuickNote: Identifiable, Codable, Equatable {
    let id = UUID()
    var title: String
    var detail: String
    var deadline: Date
    var hasDeadline: Bool
}

// Define the AtomicStreak struct
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
    
    // For the edit and delete actions
    @State private var showingDeleteConfirmation = false
    @State private var noteToDelete: QuickNote?

    @State private var noteToEdit: QuickNote?
    
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
            
            // Floating Add Note Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingAddNote = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.blue))
                            .shadow(radius: 10)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { loadQuickNotes() }
        .onChange(of: quickNotes) { _ in
            saveQuickNotes()
        }
        .sheet(isPresented: $showingAddNote) {
            AddNoteView(note: $newNote, onSave: {
                quickNotes.append(newNote)
                newNote = QuickNote(title: "", detail: "", deadline: Date(), hasDeadline: false)
                showingAddNote = false
            })
        }
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Are you sure?"),
                message: Text("This action will delete the note permanently."),
                primaryButton: .destructive(Text("Delete")) {
                    if let note = noteToDelete {
                        quickNotes.removeAll { $0.id == note.id }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var headerView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing))
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

    private var streakView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Streaks")
                .font(.headline)
                .padding(.leading, 5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(streaks) { streak in
                        Text(streak.name)
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
    
    private var quickNotesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quick Notes")
                .font(.headline)
                .padding(.bottom, 5)
            
            ForEach(quickNotes) { note in
                quickNoteRow(note: note)
                    .onLongPressGesture {
                        noteToDelete = note
                        showingDeleteConfirmation = true
                    }
                    .onTapGesture {
                        noteToEdit = note
                        showingAddNote = true
                    }
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
        dateFormatter.dateFormat = "d MMMM"
        
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE"
        let weekdayName = weekdayFormatter.string(from: date)
        
        let formattedDate = dateFormatter.string(from: date)
        if daysDifference < 7 {
            return "This \(weekdayName), \(formattedDate)"
        } else {
            return "\(formattedDate), \(weekdayName)"
        }
    }

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

    private func saveQuickNotes() {
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

struct AddNoteView: View {
    @Binding var note: QuickNote
    var onSave: () -> Void
    
    var body: some View {
        VStack {
            Text("Edit Note")
                .font(.title)
                .padding()
            
            TextField("Title", text: $note.title)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            TextField("Detail", text: $note.detail)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Toggle("Has Deadline", isOn: $note.hasDeadline)
                .padding()
            
            if note.hasDeadline {
                DatePicker("Deadline", selection: $note.deadline, displayedComponents: .date)
                    .padding()
            }
            
            Button("Save") {
                onSave()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
