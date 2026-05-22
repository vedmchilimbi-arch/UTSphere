// UTSphere — AppViewModel.swift
// Developer 1 owns this file.
//
// Single source of truth for the entire app.
// All views observe this via @EnvironmentObject — no data is passed
// directly between views, keeping everything loosely coupled.

import Foundation
import Combine

class AppViewModel: ObservableObject {

    // MARK: - Published state (all UI observes these)

    @Published var resources: [Resource] = SeedData.resources
    @Published var bookings: [Booking] = []
    @Published var events: [StudentEvent] = SeedData.events
    @Published var clubs: [Club] = SeedData.clubs
    @Published var rsvps: [RSVP] = []
    @Published var joinedClubIDs: Set<UUID> = []
    @Published var profile: UserProfile = SeedData.defaultProfile
    @Published var showProfileSheet: Bool = false

    // MARK: - Computed filtered lists (Dev 2 uses these in DashboardView)

    var spaces: [Resource] {
        resources.filter { $0.category == .studyRoom || $0.category == .libraryDesk || $0.category == .quietZone }
    }

    var courts: [Resource] {
        resources.filter { $0.category == .court || $0.category == .gymSlot }
    }

    // MARK: - Booking logic (Dev 1 implements, Dev 3 calls)

    /// Returns true if the resource is available for the given time window.
    func isAvailable(_ resource: Resource, from start: Date, to end: Date) -> Bool {
        !bookings.contains { booking in
            booking.resourceID == resource.id &&
            booking.status == .upcoming &&
            booking.startDate < end &&
            booking.endDate > start
        }
    }

    /// Books a resource. Returns false if a conflict exists.
    @discardableResult
    func addBooking(resource: Resource, from start: Date, to end: Date) -> Bool {
        guard isAvailable(resource, from: start, to: end) else { return false }
        let booking = Booking(
            resourceID: resource.id,
            resourceName: resource.name,
            type: resource.category == .court || resource.category == .gymSlot ? .court : .space,
            startDate: start,
            endDate: end
        )
        bookings.append(booking)
        return true
    }

    /// Cancels a booking by ID.
    func cancelBooking(id: UUID) {
        if let index = bookings.firstIndex(where: { $0.id == id }) {
            bookings[index].status = .cancelled
        }
    }

    // MARK: - Event RSVP logic

    func hasRSVPd(event: StudentEvent) -> Bool {
        rsvps.contains { $0.eventID == event.id }
    }

    @discardableResult
    func rsvp(event: StudentEvent) -> Bool {
        guard !event.isFull, !hasRSVPd(event: event) else { return false }
        rsvps.append(RSVP(eventID: event.id, eventName: event.title))
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].rsvpCount += 1
        }
        return true
    }

    func cancelRSVP(event: StudentEvent) {
        rsvps.removeAll { $0.eventID == event.id }
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].rsvpCount = max(0, events[index].rsvpCount - 1)
        }
    }

    // MARK: - Club membership

    func isJoined(_ club: Club) -> Bool {
        joinedClubIDs.contains(club.id)
    }

    func toggleMembership(_ club: Club) {
        if joinedClubIDs.contains(club.id) {
            joinedClubIDs.remove(club.id)
            if let index = clubs.firstIndex(where: { $0.id == club.id }) {
                clubs[index].memberCount = max(0, clubs[index].memberCount - 1)
            }
        } else {
            joinedClubIDs.insert(club.id)
            if let index = clubs.firstIndex(where: { $0.id == club.id }) {
                clubs[index].memberCount += 1
            }
        }
    }
}
