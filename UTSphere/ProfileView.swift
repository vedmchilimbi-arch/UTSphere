// UTSphere — ProfileView.swift
// Developer 3 owns this file.
//
// Responsibilities:
//   - Display the current user's profile (avatar, name, student ID, email, degree)
//   - Allow editing via an inline sheet
//   - Settings: notification toggles, avatar colour picker
//   - Activity summary: bookings, RSVPs, clubs (read-only from vm)
//   - Danger zone: clear all bookings with confirmation

import SwiftUI

// MARK: - Root profile view

struct ProfileView: View {

    @EnvironmentObject var vm: AppViewModel
    @State private var showEditSheet = false
    @State private var showClearBookingsAlert = false

    var body: some View {
        NavigationStack {
            List {

                // ── Section 1: Avatar + identity ──────────────────────────

                Section {
                    HStack(spacing: 16) {
                        AvatarView(
                            initials: vm.profile.initials,
                            color: vm.profile.avatarColor.color,
                            size: 64
                        )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(vm.profile.fullName)
                                .font(.headline)
                                .foregroundStyle(.primary)

                            Text(vm.profile.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text(vm.profile.studentID)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            showEditSheet = true
                        } label: {
                            Text("Edit")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .foregroundStyle(.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 6)
                }

                // ── Section 2: Academic details ───────────────────────────

                Section {
                    ProfileDetailRow(icon: "graduationcap", label: "Degree", value: vm.profile.degree)
                    ProfileDetailRow(icon: "building.columns", label: "Faculty", value: vm.profile.faculty)
                } header: {
                    Text("Academic")
                }

                // ── Section 3: Avatar colour picker ───────────────────────

                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(AvatarColor.allCases) { ac in
                            Button {
                                vm.profile.avatarColor = ac
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(ac.color)
                                        .frame(width: 36, height: 36)
                                    if vm.profile.avatarColor == ac {
                                        Image(systemName: "checkmark")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Avatar colour")
                }

                // ── Section 4: Activity summary ───────────────────────────

                Section {
                    ActivitySummaryRow(
                        icon: "calendar.badge.clock",
                        label: "Upcoming bookings",
                        count: vm.bookings.filter { $0.isUpcoming }.count,
                        color: .blue
                    )
                    ActivitySummaryRow(
                        icon: "ticket",
                        label: "RSVPd events",
                        count: vm.rsvps.count,
                        color: .orange
                    )
                    ActivitySummaryRow(
                        icon: "person.3",
                        label: "Clubs joined",
                        count: vm.joinedClubIDs.count,
                        color: .purple
                    )
                } header: {
                    Text("My activity")
                }

                // ── Section 5: Notifications ───────────────────────────────

                Section {
                    Toggle(isOn: $vm.profile.notifyBookingReminders) {
                        Label("Booking reminders", systemImage: "bell.badge")
                    }
                    .tint(.blue)

                    Toggle(isOn: $vm.profile.notifyEventAlerts) {
                        Label("Event alerts", systemImage: "calendar.badge.plus")
                    }
                    .tint(.orange)

                    Toggle(isOn: $vm.profile.notifyClubUpdates) {
                        Label("Club updates", systemImage: "person.3")
                    }
                    .tint(.purple)
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("Notification delivery requires system permission.")
                        .font(.caption)
                }

                // ── Section 6: Danger zone ─────────────────────────────────

                Section {
                    Button(role: .destructive) {
                        showClearBookingsAlert = true
                    } label: {
                        Label("Clear all bookings", systemImage: "trash")
                    }
                } header: {
                    Text("Danger zone")
                } footer: {
                    Text("This cancels every active booking. This cannot be undone.")
                        .font(.caption)
                }

            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
        }

        // ── Edit profile sheet ─────────────────────────────────────────────
        .sheet(isPresented: $showEditSheet) {
            EditProfileSheet(profile: $vm.profile)
        }

        // ── Clear bookings confirmation ────────────────────────────────────
        .alert("Clear all bookings?", isPresented: $showClearBookingsAlert) {
            Button("Clear all", role: .destructive) {
                for booking in vm.bookings where booking.status == .upcoming {
                    vm.cancelBooking(id: booking.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All \(vm.bookings.filter { $0.isUpcoming }.count) upcoming booking(s) will be cancelled.")
        }
    }
}

// MARK: - Edit profile sheet

struct EditProfileSheet: View {

    @Binding var profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    @State private var draftName: String = ""
    @State private var draftEmail: String = ""
    @State private var draftStudentID: String = ""
    @State private var draftDegree: String = ""
    @State private var draftFaculty: String = ""

    private var isNameValid: Bool { !draftName.trimmingCharacters(in: .whitespaces).isEmpty }
    private var isEmailValid: Bool {
        let trimmed = draftEmail.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".")
    }
    private var isStudentIDValid: Bool {
        let digits = draftStudentID.trimmingCharacters(in: .whitespaces)
        return !digits.isEmpty && digits.allSatisfy(\.isNumber)
    }
    private var canSave: Bool { isNameValid && isEmailValid && isStudentIDValid }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Full name")
                            .foregroundStyle(.secondary)
                        TextField("Full name", text: $draftName)
                            .multilineTextAlignment(.trailing)
                    }
                    if !isNameValid {
                        InlineWarning(icon: "exclamationmark.circle", message: "Name cannot be empty.")
                    }

                    HStack {
                        Text("Email")
                            .foregroundStyle(.secondary)
                        TextField("student@uts.edu.au", text: $draftEmail)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    if !isEmailValid {
                        InlineWarning(icon: "exclamationmark.circle", message: "Enter a valid email address.")
                    }

                    HStack {
                        Text("Student ID")
                            .foregroundStyle(.secondary)
                        TextField("8-digit ID", text: $draftStudentID)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    if !isStudentIDValid {
                        InlineWarning(icon: "exclamationmark.circle", message: "Student ID must contain only digits.")
                    }
                } header: {
                    Text("Identity")
                }

                Section {
                    HStack {
                        Text("Degree")
                            .foregroundStyle(.secondary)
                        TextField("Degree name", text: $draftDegree)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Faculty")
                            .foregroundStyle(.secondary)
                        TextField("Faculty name", text: $draftFaculty)
                            .multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Academic")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        profile.fullName  = draftName.trimmingCharacters(in: .whitespaces)
                        profile.email     = draftEmail.trimmingCharacters(in: .whitespaces)
                        profile.studentID = draftStudentID.trimmingCharacters(in: .whitespaces)
                        profile.degree    = draftDegree.trimmingCharacters(in: .whitespaces)
                        profile.faculty   = draftFaculty.trimmingCharacters(in: .whitespaces)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                draftName      = profile.fullName
                draftEmail     = profile.email
                draftStudentID = profile.studentID
                draftDegree    = profile.degree
                draftFaculty   = profile.faculty
            }
        }
    }
}

// MARK: - Avatar view (reusable initials circle)

struct AvatarView: View {
    let initials: String
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(color.gradient)
                .frame(width: size, height: size)
            Text(initials)
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Profile detail row

struct ProfileDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Activity summary row

struct ActivitySummaryRow: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(AppViewModel())
}
