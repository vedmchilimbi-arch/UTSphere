
// UTSphere — MyBookingsView.swift
// Developer 3 owns this file.
//
// Responsibilities:
//   - Show all upcoming bookings (spaces + courts)
//   - Show all RSVPd events
//   - Allow cancellation of both via swipe-to-delete + confirmation
//   - Empty states for each section
//
// Marking criteria covered:
//   - Error handling: cancel requires confirmation — no accidental deletions
//   - Immutable data: cancellation goes through vm.cancelBooking() / vm.cancelRSVP()
//   - Functional separation: each section is its own subview

import SwiftUI

struct MyBookingsView: View {

    @EnvironmentObject var vm: AppViewModel

    // MARK: - Filtered data

    private var upcomingBookings: [Booking] {
        vm.bookings
            .filter { $0.isUpcoming }
            .sorted { $0.startDate < $1.startDate }
    }

    private var rsvpdEvents: [StudentEvent] {
        vm.events.filter { event in
            vm.rsvps.contains { $0.eventID == event.id }
        }
        .sorted { $0.startDate < $1.startDate }
    }

    // MARK: - State

    @State private var bookingToCancel: Booking? = nil
    @State private var eventToCancel: StudentEvent? = nil
    @State private var showCancelBookingAlert = false
    @State private var showCancelRSVPAlert = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if upcomingBookings.isEmpty && rsvpdEvents.isEmpty {
                    EmptyStateView()
                } else {
                    List {

                        // ── Upcoming space & court bookings ──────────────

                        if !upcomingBookings.isEmpty {
                            Section {
                                ForEach(upcomingBookings) { booking in
                                    BookingDetailRow(booking: booking)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                bookingToCancel = booking
                                                showCancelBookingAlert = true
                                            } label: {
                                                Label("Cancel", systemImage: "xmark.circle")
                                            }
                                        }
                                }
                            } header: {
                                SectionHeader(
                                    icon: "calendar.badge.clock",
                                    title: "Upcoming bookings",
                                    count: upcomingBookings.count
                                )
                            }
                        }

                        // ── RSVPd events ─────────────────────────────────

                        if !rsvpdEvents.isEmpty {
                            Section {
                                ForEach(rsvpdEvents) { event in
                                    RSVPDetailRow(event: event)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                eventToCancel = event
                                                showCancelRSVPAlert = true
                                            } label: {
                                                Label("Remove", systemImage: "xmark.circle")
                                            }
                                        }
                                }
                            } header: {
                                SectionHeader(
                                    icon: "ticket",
                                    title: "My RSVPs",
                                    count: rsvpdEvents.count
                                )
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Bookings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileAvatarButton()
                }
            }

            // ── Cancel booking confirmation ───────────────────────────────
            .alert("Cancel booking?", isPresented: $showCancelBookingAlert, presenting: bookingToCancel) { booking in
                Button("Yes, cancel it", role: .destructive) {
                    vm.cancelBooking(id: booking.id)
                    bookingToCancel = nil
                }
                Button("Keep it", role: .cancel) {
                    bookingToCancel = nil
                }
            } message: { booking in
                Text("This will free up \(booking.resourceName) for other students.")
            }

            // ── Cancel RSVP confirmation ──────────────────────────────────
            .alert("Remove RSVP?", isPresented: $showCancelRSVPAlert, presenting: eventToCancel) { event in
                Button("Yes, remove it", role: .destructive) {
                    vm.cancelRSVP(event: event)
                    eventToCancel = nil
                }
                Button("Keep it", role: .cancel) {
                    eventToCancel = nil
                }
            } message: { event in
                Text("Your spot at \(event.title) will be released.")
            }
        }
    }
}

// MARK: - Booking detail row

struct BookingDetailRow: View {
    let booking: Booking

    private var timeRangeLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        let start = fmt.string(from: booking.startDate)
        let endFmt = DateFormatter()
        endFmt.timeStyle = .short
        let end = endFmt.string(from: booking.endDate)
        return "\(start) – \(end)"
    }

    private var durationLabel: String {
        let mins = Int(booking.endDate.timeIntervalSince(booking.startDate) / 60)
        let hrs = mins / 60
        let remaining = mins % 60
        if remaining == 0 { return "\(hrs) hr\(hrs > 1 ? "s" : "")" }
        return "\(hrs)h \(remaining)m"
    }

    // Colour-codes how soon the booking is
    private var urgencyColor: Color {
        let hours = booking.startDate.timeIntervalSinceNow / 3600
        if hours < 1 { return .red }
        if hours < 24 { return .orange }
        return .blue
    }

    var body: some View {
        HStack(spacing: 14) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 3)
                .fill(urgencyColor)
                .frame(width: 4)
                .frame(height: 56)

            VStack(alignment: .leading, spacing: 5) {
                Text(booking.resourceName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Label(timeRangeLabel, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    // Type pill
                    Text(booking.type.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())

                    // Duration pill
                    Text(durationLabel)
                        .font(.caption2)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.1))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())

                    // Soon indicator
                    if booking.startDate.timeIntervalSinceNow < 3600 {
                        Text("Starting soon")
                            .font(.caption2)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            // Countdown
            VStack(alignment: .trailing, spacing: 2) {
                Text(booking.startDate, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
                Text("from now")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - RSVP detail row

struct RSVPDetailRow: View {
    let event: StudentEvent

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: event.category.icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 40, height: 40)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Label(
                    event.startDate.formatted(date: .abbreviated, time: .shortened),
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Label(event.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                // RSVP confirmed badge
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.title3)

                Text("RSVP'd")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let icon: String
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .textCase(nil)
            Spacer()
            Text("\(count)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Empty state

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.blue.opacity(0.3))

            VStack(spacing: 6) {
                Text("No bookings yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("Book a study room, court, or\nRSVP to an event to see it here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("With bookings") {
    let vm = AppViewModel()
    // Seed a booking for preview
    let resource = SeedData.resources[0]
    let start = Date.now.addingTimeInterval(3600)
    let end = start.addingTimeInterval(3600)
    _ = vm.addBooking(resource: resource, from: start, to: end)
    _ = vm.rsvp(event: SeedData.events[0])
    return MyBookingsView().environmentObject(vm)
}

#Preview("Empty") {
    MyBookingsView()
        .environmentObject(AppViewModel())
}
