//
//  Dashboard1View.swift
//  Atomic Habits
//
//  Created by Apeel Subedi on 27/01/2025.
//

import SwiftUI

struct Dashboard1View: View {
    @State private var weight: Double = 70.0
    @State private var height: Double = 170.0
    @State private var isEditingProfile: Bool = false
    @State private var runningDistance: Double = 0.0
    @State private var caloriesBurned: Int = 0
    
    private let darkYellow = Color(red: 0.8, green: 0.7, blue: 0.0)
    
    var body: some View {
        ZStack {
            darkYellow.opacity(0.9)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    profileCard
                    activityCards
                }
                .padding()
            }
        }
        .sheet(isPresented: $isEditingProfile) {
            ProfileEditView(weight: $weight, height: $height)
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Fitness Dashboard")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            Button(action: { isEditingProfile = true }) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
    }
    
    private var profileCard: some View {
        VStack(spacing: 15) {
            HStack {
                statView(title: "Weight", value: String(format: "%.1f kg", weight))
                Divider().background(Color.white.opacity(0.5))
                statView(title: "Height", value: String(format: "%.1f cm", height))
                Divider().background(Color.white.opacity(0.5))
                statView(title: "BMI", value: String(format: "%.1f", calculateBMI()))
            }
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
    }
    
    private var activityCards: some View {
        VStack(spacing: 20) {
            activityCard(title: "Running Distance", value: String(format: "%.1f km", runningDistance), icon: "figure.run")
            activityCard(title: "Calories Burned", value: "\(caloriesBurned)", icon: "flame.fill")
            goalProgressView
        }
    }
    
    private func activityCard(title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.white)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
    }
    
    private var goalProgressView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Daily Goal Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            ProgressView(value: 0.7)
                .progressViewStyle(LinearProgressViewStyle(tint: .white))
            
            Text("70% Completed")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
    }
    
    private func statView(title: String, value: String) -> some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    private func calculateBMI() -> Double {
        let heightInMeters = height / 100
        return weight / (heightInMeters * heightInMeters)
    }
}

struct ProfileEditView: View {
    @Binding var weight: Double
    @Binding var height: Double
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("Weight", value: $weight, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Height (cm)")
                        Spacer()
                        TextField("Height", value: $height, formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationBarTitle("Edit Profile", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct Dashboard1View_Previews: PreviewProvider {
    static var previews: some View {
        Dashboard1View()
    }
}

