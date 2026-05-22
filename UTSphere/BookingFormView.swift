// UTSphere — BookingFormView.swift
// Developer 3 owns this file.
//
// Responsibilities:
//   - Capture user input (date, start time, duration) via @State
//   - Validate all input before allowing confirmation
//   - Detect booking conflicts by calling vm.isAvailable()
//   - Guide the user toward valid input — never silently fail
//
// Marking criteria covered:
//   - Error handling: conflicts shown as inline alerts, invalid inputs disabled
//   - Immutable data: booking only created via vm.addBooking() — no direct mutation
//   - @State / @Binding: all form fields use @State; passed down via @Binding where needed

import SwiftUI

struct BookingFormView: View {

    // MARK: - Dependencies

    @EnvironmentObject var vm: AppViewModel
    @Environment(\.dismiss) private var dismiss

    let resource: Resource

    // MARK: - Form state (@State — Dev 3 owns all of these)

    @State private var selectedDate: Date
    @State private var startHour: Int
    @State private var durationHours: Int = 1
    @State private var showConfirmation: Bool = false
    @State private var showSuccessBanner: Bool = false
    @State private var conflictMessage: String? = nil

    // MARK: - Init (supports pre-filling from availability timeline)

    init(resource: Resource,
         initialDate: Date = Calendar.current.startOfDay(for: .now),
         initialHour: Int? = nil) {
        self.resource = resource
        _selectedDate = State(initialValue: initialDate)
        let smart = initialHour ?? Self.smartStartHour(for: initialDate)
        _startHour = State(initialValue: min(max(smart, 8), 21))
    }

    /// Returns the next round hour from now when date is today, otherwise 9 AM.
    private static func smartStartHour(for date: Date) -> Int {
        let cal = Calendar.current
        guard cal.isDateInToday(date) else { return 9 }
        let comps = cal.dateComponents([.hour, .minute], from: .now)
        let h = comps.hour ?? 9
        let m = comps.minute ?? 0
        return m > 0 ? h + 1 : h
    }

    // MARK: - Computed date values

    private var startDate: Date {
        Calendar.current.date(
            bySettingHour: startHour, minute: 0, second: 0,
            of: selectedDate
        ) ?? selectedDate
    }

    private var endDate: Date {
        startDate.addingTimeInterval(Double(durationHours) * 3600)
    }

    // MARK: - Validation logic

    /// True if the selected date+time is in the future
    private var isDateValid: Bool {
        startDate > Date.now
    }

    /// True if duration doesn't exceed the resource's max
    private var isDurationValid: Bool {
        durationHours <= resource.maxBookingHours
    }

    /// True if no existing booking overlaps this window
    private var isAvailable: Bool {
        vm.isAvailable(resource, from: startDate, to: endDate)
    }

    /// True if the booking ends by 10 PM (hour 22) — operating hours cutoff
    private var isEndTimeValid: Bool {
        (startHour + durationHours) <= 22
    }

    /// True only when ALL conditions pass — enables the confirm button
    private var canBook: Bool {
        isDateValid && isDurationValid && isEndTimeValid && isAvailable
    }

    // MARK: - Allowed hours (8 AM – 9 PM)

    private let allowedHours = Array(8...21)

    // MARK: - Body

    var body: some View {
        Form {

                // ── Section 1: Resource summary ──────────────────────────

                Section {
                    HStack(spacing: 14) {
                        Image(systemName: resource.category.icon)
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 48, height: 48)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(resource.name)
                                .font(.headline)
                            Text(resource.locationLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("Max \(resource.maxBookingHours) hour\(resource.maxBookingHours > 1 ? "s" : "") per booking")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // ── Section 2: Pick a date ───────────────────────────────

                Section {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: Date.now...,            // prevents past date selection
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .onChange(of: selectedDate) { _, _ in
                        validateAndClearConflict()
                    }
                } header: {
                    Text("Select a date")
                }

                // ── Section 3: Start time ────────────────────────────────

                Section {
                    Picker("Start time", selection: $startHour) {
                        ForEach(allowedHours, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .onChange(of: startHour) { _, _ in
                        validateAndClearConflict()
                    }

                    // Inline error: past time
                    if !isDateValid {
                        InlineWarning(
                            icon: "clock.badge.exclamationmark",
                            message: "This time has already passed. Please choose a future time."
                        )
                    }
                } header: {
                    Text("Start time")
                }

                // ── Section 4: Duration ──────────────────────────────────

                Section {
                    HStack {
                        Text("Duration")
                        Spacer()

                        // Stepper with inline value display
                        HStack(spacing: 12) {
                            Button {
                                if durationHours > 1 {
                                    durationHours -= 1
                                    validateAndClearConflict()
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(durationHours > 1 ? .blue : .gray)
                            }
                            .buttonStyle(.plain)

                            Text("\(durationHours) hr\(durationHours > 1 ? "s" : "")")
                                .font(.headline)
                                .frame(minWidth: 52)
                                .multilineTextAlignment(.center)

                            Button {
                                if durationHours < resource.maxBookingHours {
                                    durationHours += 1
                                    validateAndClearConflict()
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(
                                        durationHours < resource.maxBookingHours ? .blue : .gray
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)

                    Text("Maximum allowed: \(resource.maxBookingHours) hr\(resource.maxBookingHours > 1 ? "s" : "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Duration")
                }

                // ── Section 5: Booking summary ───────────────────────────

                Section {
                    BookingSummaryRow(
                        icon: "calendar",
                        label: "Date",
                        value: selectedDate.formatted(date: .long, time: .omitted)
                    )
                    BookingSummaryRow(
                        icon: "clock",
                        label: "Time",
                        value: "\(formatHour(startHour)) – \(formatHour(startHour + durationHours))"
                    )
                    BookingSummaryRow(
                        icon: "hourglass",
                        label: "Duration",
                        value: "\(durationHours) hour\(durationHours > 1 ? "s" : "")"
                    )

                    // Conflict error — shown only after user triggers check
                    if let conflict = conflictMessage {
                        InlineWarning(icon: "exclamationmark.octagon.fill", message: conflict)
                    }

                    // Operating hours error
                    if !isEndTimeValid {
                        InlineWarning(
                            icon: "moon.zzz",
                            message: "Bookings must end by 10 PM. Reduce duration or choose an earlier start time."
                        )
                    }

                    // Availability indicator
                    if isDateValid && isDurationValid && isEndTimeValid {
                        HStack(spacing: 8) {
                            Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(isAvailable ? .green : .red)
                            Text(isAvailable ? "This slot is available" : "Slot already booked")
                                .font(.subheadline)
                                .foregroundStyle(isAvailable ? .green : .red)
                        }
                        .padding(.vertical, 2)
                    }

                } header: {
                    Text("Booking summary")
                }

                // ── Section 6: Confirm button ────────────────────────────

                Section {
                    Button {
                        showConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Confirm booking", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                                .foregroundStyle(Color.white)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(canBook ? Color.blue : Color.gray.opacity(0.3))
                    .disabled(!canBook)
                }
                footer: {
                    if !canBook {
                        Text("Fix the issues above before confirming.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

        } // end Form
        .navigationTitle("Book \(resource.category.rawValue)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }

        // ── Confirmation alert ───────────────────────────────────────
        .confirmationDialog(
            "Confirm booking?",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            Button("Book \(resource.name)") {
                submitBooking()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(selectedDate.formatted(date: .abbreviated, time: .omitted)) · \(formatHour(startHour)) – \(formatHour(startHour + durationHours))")
        }

        // ── Success banner overlay ───────────────────────────────────
        .overlay(alignment: .top) {
            if showSuccessBanner {
                SuccessBanner(resourceName: resource.name)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.spring(duration: 0.4), value: showSuccessBanner)
    }

    // MARK: - Actions

    private func submitBooking() {
        let success = vm.addBooking(resource: resource, from: startDate, to: endDate)
        if success {
            withAnimation {
                showSuccessBanner = true
            }
            // Auto-dismiss banner then pop the view
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showSuccessBanner = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    dismiss()
                }
            }
        } else {
            // Double-check failed — show conflict message inline
            conflictMessage = "This slot was just taken. Please choose a different time."
        }
    }

    private func validateAndClearConflict() {
        conflictMessage = nil
    }

    // MARK: - Helpers

    private func formatHour(_ hour: Int) -> String {
        let wrapped = hour % 24
        let isNextDay = hour >= 24
        var comps = DateComponents()
        comps.hour = wrapped
        comps.minute = 0
        let date = Calendar.current.date(from: comps) ?? Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "h a"
        let label = fmt.string(from: date)
        return isNextDay ? "\(label) (+1)" : label
    }
}

// MARK: - Subviews

/// Yellow inline warning row used for validation messages
struct InlineWarning: View {
    let icon: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .font(.subheadline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
    }
}

/// Single row in the booking summary table
struct BookingSummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

/// Green success banner that slides in from the top
struct SuccessBanner: View {
    let resourceName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Color.white)
            VStack(alignment: .leading, spacing: 2) {
                Text("Booking confirmed!")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.white)
                Text(resourceName)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.green)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

// MARK: - Preview

#Preview {
    BookingFormView(resource: SeedData.resources[0])
        .environmentObject(AppViewModel())
}
