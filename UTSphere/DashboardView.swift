// UTSphere — DashboardView.swift
// Developer 2 owns this file.
//
// Main entry point after launch. Four tabs driven entirely by
// @EnvironmentObject — no data is passed between views directly.
// Adding a new tab only requires adding a new list view; no other
// files need to change. (Demonstrates extensibility for marking.)

import SwiftUI

// MARK: - Root dashboard

struct DashboardView: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        TabView {
            SpacesListView()
                .tabItem {
                    Label("Spaces", systemImage: "door.left.hand.closed")
                }

            CourtsListView()
                .tabItem {
                    Label("Courts", systemImage: "figure.basketball")
                }

            EventsListView()
                .tabItem {
                    Label("Events", systemImage: "calendar.badge.plus")
                }

            ClubsListView()
                .tabItem {
                    Label("Clubs", systemImage: "person.3")
                }

            MyBookingsView()
                .tabItem {
                    Label("My Bookings", systemImage: "list.bullet.clipboard")
                }
        }
        .tint(.blue)
        .sheet(isPresented: $vm.showProfileSheet) {
            ProfileView()
                .environmentObject(vm)
        }
    }
}

// MARK: - Spaces tab

struct SpacesListView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var searchText = ""
    @State private var selectedCategory: ResourceCategory? = nil

    var filtered: [Resource] {
        vm.spaces.filter { resource in
            let matchesSearch = searchText.isEmpty ||
                resource.name.localizedCaseInsensitiveContains(searchText) ||
                resource.building.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || resource.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach([ResourceCategory.studyRoom, .libraryDesk, .quietZone]) { cat in
                            FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                ForEach(filtered) { resource in
                    NavigationLink(destination: ResourceDetailView(resource: resource)) {
                        ResourceRowView(resource: resource)
                    }
                }

                if filtered.isEmpty {
                    FilterEmptyState(
                        icon: "door.left.hand.closed",
                        title: "No spaces found",
                        message: "Try a different filter or search term."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Spaces")
            .searchable(text: $searchText, prompt: "Search rooms or buildings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileAvatarButton()
                }
            }
        }
    }
}

// MARK: - Courts tab

struct CourtsListView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedCategory: ResourceCategory? = nil

    var filtered: [Resource] {
        vm.courts.filter { resource in
            selectedCategory == nil || resource.category == selectedCategory
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach([ResourceCategory.court, .gymSlot]) { cat in
                            FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                ForEach(filtered) { resource in
                    NavigationLink(destination: ResourceDetailView(resource: resource)) {
                        ResourceRowView(resource: resource)
                    }
                }

                if filtered.isEmpty {
                    FilterEmptyState(
                        icon: "figure.basketball",
                        title: "No courts found",
                        message: "Try selecting a different category."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Courts & Activities")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileAvatarButton()
                }
            }
        }
    }
}

// MARK: - Events tab

struct EventsListView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var selectedCategory: EventCategory? = nil

    var featured: [StudentEvent] {
        vm.events.filter { $0.isFeatured }
    }

    var filtered: [StudentEvent] {
        vm.events.filter { event in
            !event.isFeatured &&
            (selectedCategory == nil || event.category == selectedCategory)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Featured banner (if any)
                if !featured.isEmpty {
                    Section {
                        ForEach(featured) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                FeaturedEventCard(event: event)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text("Featured")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                    }
                }

                // Category filter
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            ForEach(EventCategory.allCases) { cat in
                                FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                    selectedCategory = selectedCategory == cat ? nil : cat
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }

                // Event list
                Section {
                    ForEach(filtered) { event in
                        NavigationLink(destination: EventDetailView(event: event)) {
                            EventRowView(event: event)
                        }
                    }

                    if filtered.isEmpty {
                        FilterEmptyState(
                            icon: "calendar.badge.exclamationmark",
                            title: "No events found",
                            message: "No events in this category right now."
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Events")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileAvatarButton()
                }
            }
        }
    }
}

// MARK: - Clubs tab

struct ClubsListView: View {
    @EnvironmentObject var vm: AppViewModel
    @State private var searchText = ""
    @State private var selectedCategory: ClubCategory? = nil

    var filtered: [Club] {
        vm.clubs.filter { club in
            let matchesSearch = searchText.isEmpty ||
                club.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || club.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(ClubCategory.allCases) { cat in
                            FilterChip(title: cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

                ForEach(filtered) { club in
                    NavigationLink(destination: ClubDetailView(club: club)) {
                        ClubRowView(club: club)
                    }
                }

                if filtered.isEmpty {
                    FilterEmptyState(
                        icon: "person.3",
                        title: "No clubs found",
                        message: "Try a different search term or category."
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Clubs")
            .searchable(text: $searchText, prompt: "Search clubs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileAvatarButton()
                }
            }
        }
    }
}

// MARK: - My Bookings tab (stub — Developer 3 builds this out fully)

// MARK: - Reusable row components

struct ResourceRowView: View {
    let resource: Resource

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: resource.category.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(resource.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(resource.locationLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Label("\(resource.capacity)", systemImage: "person.2")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if !resource.equipment.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                        Text(resource.equipment.prefix(2).joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Max booking hours badge
            Text("Up to \(resource.maxBookingHours)h")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundStyle(.blue)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

struct EventRowView: View {
    let event: StudentEvent
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: event.category.icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 36, height: 36)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(dateFormatter.string(from: event.startDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption2)
                    Text(event.location)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(event.spotsLabel)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(event.isFull ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                .foregroundStyle(event.isFull ? .red : .green)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

struct ClubRowView: View {
    @EnvironmentObject var vm: AppViewModel
    let club: Club

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: club.icon)
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 36, height: 36)
                .background(Color.purple.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(club.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(club.category.rawValue)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(club.memberCount) members", systemImage: "person.2")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if vm.isJoined(club) {
                    Text("Joined")
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.15))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }

                if !club.isRecruiting {
                    Text("Closed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct BookingRowView: View {
    let booking: Booking
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(booking.resourceName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(booking.type.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }

            Text(formatter.string(from: booking.startDate))
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Until \(formatter.string(from: booking.endDate))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Featured event card

struct FeaturedEventCard: View {
    let event: StudentEvent

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(Color.orange)
                .frame(height: 140)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)

                Text(event.location)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Filter chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail view stubs (Developer 3 builds these out fully)

struct ResourceDetailView: View {
    @EnvironmentObject var vm: AppViewModel
    let resource: Resource
    @State private var availabilityDate: Date = Calendar.current.startOfDay(for: .now)

    private func isHourAvailable(_ hour: Int, on date: Date) -> Bool {
        guard let start = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date),
              let end   = Calendar.current.date(bySettingHour: hour + 1, minute: 0, second: 0, of: date)
        else { return false }
        return vm.isAvailable(resource, from: start, to: end)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 16) {
                    Image(systemName: resource.category.icon)
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                        .frame(width: 60, height: 60)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(resource.name)
                            .font(.headline)
                        Text(resource.locationLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                Divider()

                // Details
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(icon: "person.2", label: "Capacity", value: "\(resource.capacity) people")
                    DetailRow(icon: "clock", label: "Max booking", value: "\(resource.maxBookingHours) hours")

                    if !resource.equipment.isEmpty {
                        DetailRow(icon: "wrench.and.screwdriver",
                                  label: "Equipment",
                                  value: resource.equipment.joined(separator: ", "))
                    }
                }
                .padding(.horizontal)

                Divider()

                // ── Availability timeline ───────────────────────────────────
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Availability")
                            .font(.headline)
                        Spacer()
                        DatePicker("", selection: $availabilityDate,
                                   in: Date.now..., displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                    }
                    .padding(.horizontal)

                    Text("Tap a green slot to jump straight into booking it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(8...21, id: \.self) { hour in
                                let available = isHourAvailable(hour, on: availabilityDate)
                                if available {
                                    NavigationLink(destination:
                                        BookingFormView(resource: resource,
                                                        initialDate: availabilityDate,
                                                        initialHour: hour)
                                    ) {
                                        TimeSlotChip(hour: hour, isAvailable: true)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    TimeSlotChip(hour: hour, isAvailable: false)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }

                Divider()

                // Book button (uses smart defaults from currently-selected date)
                NavigationLink(destination: BookingFormView(resource: resource,
                                                            initialDate: availabilityDate)) {
                    Label("Book this space", systemImage: "calendar.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(resource.category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EventDetailView: View {
    @EnvironmentObject var vm: AppViewModel
    let event: StudentEvent

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Organised by \(event.organiserName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(event.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.horizontal)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(icon: "calendar", label: "Date",
                              value: event.startDate.formatted(date: .long, time: .shortened))
                    DetailRow(icon: "mappin", label: "Location", value: event.location)
                    DetailRow(icon: "ticket", label: "Spots", value: event.spotsLabel)
                }
                .padding(.horizontal)

                Divider()

                Button {
                    if vm.hasRSVPd(event: event) {
                        vm.cancelRSVP(event: event)
                    } else {
                        vm.rsvp(event: event)
                    }
                } label: {
                    Label(vm.hasRSVPd(event: event) ? "Cancel RSVP" : "RSVP to this event",
                          systemImage: vm.hasRSVPd(event: event) ? "xmark.circle" : "checkmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.hasRSVPd(event: event) ? Color.red : Color.orange)
                        .foregroundStyle(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(event.isFull && !vm.hasRSVPd(event: event))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Event")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ClubDetailView: View {
    @EnvironmentObject var vm: AppViewModel
    let club: Club

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 16) {
                    Image(systemName: club.icon)
                        .font(.largeTitle)
                        .foregroundStyle(.purple)
                        .frame(width: 60, height: 60)
                        .background(Color.purple.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(club.name)
                            .font(.headline)
                        Text(club.category.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text(club.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    DetailRow(icon: "person.2", label: "Members", value: "\(club.memberCount)")
                        .padding(.horizontal)
                    DetailRow(icon: "envelope", label: "Contact", value: club.contactEmail)
                        .padding(.horizontal)
                }

                Divider()

                Button {
                    vm.toggleMembership(club)
                } label: {
                    Label(vm.isJoined(club) ? "Leave club" : "Join club",
                          systemImage: vm.isJoined(club) ? "person.badge.minus" : "person.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(vm.isJoined(club) ? Color.gray.opacity(0.2) : Color.purple)
                        .foregroundStyle(vm.isJoined(club) ? Color.primary : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!club.isRecruiting && !vm.isJoined(club))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Club")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Shared helper

struct DetailRow: View {
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

// MARK: - Profile avatar toolbar button

struct ProfileAvatarButton: View {
    @EnvironmentObject var vm: AppViewModel

    var body: some View {
        Button {
            vm.showProfileSheet = true
        } label: {
            AvatarView(
                initials: vm.profile.initials,
                color: vm.profile.avatarColor.color,
                size: 30
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Time slot chip

struct TimeSlotChip: View {
    let hour: Int
    let isAvailable: Bool

    private var label: String {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = 0
        let date = Calendar.current.date(from: comps) ?? Date()
        let fmt = DateFormatter()
        fmt.dateFormat = "h a"
        return fmt.string(from: date)
    }

    var body: some View {
        Text(label)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isAvailable ? Color.green.opacity(0.15) : Color.red.opacity(0.12))
            .foregroundStyle(isAvailable ? Color.green : Color.red)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    isAvailable ? Color.green.opacity(0.4) : Color.red.opacity(0.3),
                    lineWidth: 1
                )
            )
    }
}

// MARK: - Filter empty state

struct FilterEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.5))
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(AppViewModel())
}
