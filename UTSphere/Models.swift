// UTSphere — Models.swift
// Developer 1 owns this file.
//
// All types are simple Swift value types (structs + enums).
// No SwiftData dependency — keeps things simple for MVP.
// Immutability enforced: mutations only happen through AppViewModel methods.

import Foundation
import SwiftUI

// MARK: - Resource (covers Spaces, Courts, and equipment)

enum ResourceCategory: String, CaseIterable, Identifiable {
    case studyRoom   = "Study Room"
    case libraryDesk = "Library Desk"
    case quietZone   = "Quiet Zone"
    case court       = "Court"
    case gymSlot     = "Gym Slot"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .studyRoom:   return "door.left.hand.closed"
        case .libraryDesk: return "books.vertical"
        case .quietZone:   return "moon"
        case .court:       return "figure.basketball"
        case .gymSlot:     return "dumbbell"
        }
    }
}

struct Resource: Identifiable {
    let id: UUID
    let name: String
    let building: String
    let floor: Int
    let category: ResourceCategory
    let capacity: Int
    let equipment: [String]
    let maxBookingHours: Int

    init(
        name: String,
        building: String,
        floor: Int,
        category: ResourceCategory,
        capacity: Int,
        equipment: [String] = [],
        maxBookingHours: Int = 3
    ) {
        self.id = UUID()
        self.name = name
        self.building = building
        self.floor = floor
        self.category = category
        self.capacity = capacity
        self.equipment = equipment
        self.maxBookingHours = maxBookingHours
    }

    var locationLabel: String { "\(building) · Floor \(floor)" }
}

// MARK: - Booking

enum BookingStatus: String {
    case upcoming  = "Upcoming"
    case cancelled = "Cancelled"
}

enum BookingType: String {
    case space = "Space"
    case court = "Court"
}

struct Booking: Identifiable {
    let id: UUID
    let resourceID: UUID
    let resourceName: String
    let type: BookingType
    let startDate: Date
    let endDate: Date
    var status: BookingStatus

    init(resourceID: UUID, resourceName: String, type: BookingType, startDate: Date, endDate: Date) {
        self.id = UUID()
        self.resourceID = resourceID
        self.resourceName = resourceName
        self.type = type
        self.startDate = startDate
        self.endDate = endDate
        self.status = .upcoming
    }

    var isUpcoming: Bool { startDate > .now && status == .upcoming }
}

// MARK: - Student Event

enum EventCategory: String, CaseIterable, Identifiable {
    case social    = "Social"
    case academic  = "Academic"
    case sport     = "Sport"
    case career    = "Career"
    case workshop  = "Workshop"
    case cultural  = "Cultural"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .social:   return "person.3"
        case .academic: return "graduationcap"
        case .sport:    return "figure.run"
        case .career:   return "briefcase"
        case .workshop: return "wrench.and.screwdriver"
        case .cultural: return "globe"
        }
    }
}

struct StudentEvent: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: EventCategory
    let organiserName: String
    let startDate: Date
    let endDate: Date
    let location: String
    let capacity: Int       // 0 = unlimited
    var rsvpCount: Int
    let isFeatured: Bool

    init(
        title: String,
        description: String,
        category: EventCategory,
        organiserName: String,
        startDate: Date,
        endDate: Date,
        location: String,
        capacity: Int = 0,
        isFeatured: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.category = category
        self.organiserName = organiserName
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.capacity = capacity
        self.rsvpCount = 0
        self.isFeatured = isFeatured
    }

    var isFull: Bool { capacity > 0 && rsvpCount >= capacity }

    var spotsLabel: String {
        guard capacity > 0 else { return "Open" }
        let remaining = max(0, capacity - rsvpCount)
        return "\(remaining) spots left"
    }
}

// MARK: - Club

enum ClubCategory: String, CaseIterable, Identifiable {
    case sport     = "Sport"
    case tech      = "Tech"
    case cultural  = "Cultural"
    case academic  = "Academic"
    case arts      = "Arts"
    case volunteer = "Volunteer"

    var id: String { rawValue }
}

struct Club: Identifiable {
    let id: UUID
    let name: String
    let description: String
    let category: ClubCategory
    var memberCount: Int
    let contactEmail: String
    let icon: String
    let isRecruiting: Bool

    init(
        name: String,
        description: String,
        category: ClubCategory,
        memberCount: Int = 0,
        contactEmail: String,
        icon: String = "person.3",
        isRecruiting: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.category = category
        self.memberCount = memberCount
        self.contactEmail = contactEmail
        self.icon = icon
        self.isRecruiting = isRecruiting
    }
}

// MARK: - RSVP

struct RSVP: Identifiable {
    let id: UUID
    let eventID: UUID
    let eventName: String

    init(eventID: UUID, eventName: String) {
        self.id = UUID()
        self.eventID = eventID
        self.eventName = eventName
    }
}

// MARK: - User Profile

enum AvatarColor: String, CaseIterable, Identifiable {
    case blue    = "Blue"
    case purple  = "Purple"
    case green   = "Green"
    case orange  = "Orange"
    case red     = "Red"
    case teal    = "Teal"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue:   return .blue
        case .purple: return .purple
        case .green:  return .green
        case .orange: return .orange
        case .red:    return .red
        case .teal:   return .teal
        }
    }
}

struct UserProfile {
    var fullName: String
    var studentID: String
    var email: String
    var degree: String
    var faculty: String
    var avatarColor: AvatarColor
    var notifyBookingReminders: Bool
    var notifyEventAlerts: Bool
    var notifyClubUpdates: Bool

    var initials: String {
        let parts = fullName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}

// MARK: - Seed data

struct SeedData {

    static let resources: [Resource] = [
        Resource(name: "Room CB01.02.050", building: "CB01", floor: 2,
                 category: .studyRoom, capacity: 6, equipment: ["Whiteboard", "TV"], maxBookingHours: 3),
        Resource(name: "Room CB01.02.060", building: "CB01", floor: 2,
                 category: .studyRoom, capacity: 4, equipment: ["Whiteboard"], maxBookingHours: 2),
        Resource(name: "Room CB11.B2.06", building: "CB11", floor: -2,
                 category: .studyRoom, capacity: 8, equipment: ["Projector", "Whiteboard"], maxBookingHours: 3),
        Resource(name: "Library Carrel A1", building: "CB01", floor: 1,
                 category: .libraryDesk, capacity: 1, equipment: [], maxBookingHours: 4),
        Resource(name: "Library Carrel B3", building: "CB01", floor: 1,
                 category: .libraryDesk, capacity: 1, equipment: [], maxBookingHours: 4),
        Resource(name: "Quiet Zone — Level 3", building: "CB01", floor: 3,
                 category: .quietZone, capacity: 20, equipment: [], maxBookingHours: 4),
        Resource(name: "Basketball Court 1", building: "Sports Centre", floor: 0,
                 category: .court, capacity: 10, equipment: [], maxBookingHours: 2),
        Resource(name: "Tennis Court A", building: "Sports Centre", floor: 0,
                 category: .court, capacity: 4, equipment: [], maxBookingHours: 1),
        Resource(name: "Badminton Court 2", building: "Sports Centre", floor: 0,
                 category: .court, capacity: 4, equipment: [], maxBookingHours: 1),
        Resource(name: "Gym Slot — Morning", building: "Sports Centre", floor: 1,
                 category: .gymSlot, capacity: 15, equipment: [], maxBookingHours: 2),
    ]

    static let events: [StudentEvent] = {
        let now = Date.now
        return [
            StudentEvent(title: "O-Week Welcome Party",
                         description: "Kick off the semester with free food, games, and giveaways.",
                         category: .social, organiserName: "UTS Student Association",
                         startDate: now.addingTimeInterval(86400 * 2),
                         endDate: now.addingTimeInterval(86400 * 2 + 10800),
                         location: "UTS Great Hall", capacity: 500, isFeatured: true),
            StudentEvent(title: "Resume Workshop",
                         description: "Get your resume reviewed by industry professionals.",
                         category: .career, organiserName: "UTS Careers",
                         startDate: now.addingTimeInterval(86400 * 5),
                         endDate: now.addingTimeInterval(86400 * 5 + 5400),
                         location: "CB11.B2.06", capacity: 30),
            StudentEvent(title: "Swift & iOS Dev Night",
                         description: "Monthly meetup for iOS developers — all levels welcome.",
                         category: .workshop, organiserName: "UTS Robotics Club",
                         startDate: now.addingTimeInterval(86400 * 7),
                         endDate: now.addingTimeInterval(86400 * 7 + 7200),
                         location: "CB11.B2.06", capacity: 40),
            StudentEvent(title: "Cultural Food Fair",
                         description: "Explore cuisines from 20+ countries brought by UTS student clubs.",
                         category: .cultural, organiserName: "UTS CSA",
                         startDate: now.addingTimeInterval(86400 * 10),
                         endDate: now.addingTimeInterval(86400 * 10 + 14400),
                         location: "Alumni Green", capacity: 0),
        ]
    }()

    static let clubs: [Club] = [
        Club(name: "UTS Robotics Club", description: "Build and compete with autonomous robots.",
             category: .tech, memberCount: 84, contactEmail: "robotics@uts.edu.au",
             icon: "cpu", isRecruiting: true),
        Club(name: "UTS Basketball Association", description: "Compete in the UniSport league.",
             category: .sport, memberCount: 120, contactEmail: "basketball@uts.edu.au",
             icon: "figure.basketball", isRecruiting: true),
        Club(name: "UTS Film Society", description: "Screenings, discussions, and filmmaking workshops.",
             category: .arts, memberCount: 56, contactEmail: "film@uts.edu.au",
             icon: "film", isRecruiting: true),
        Club(name: "UTS Sustainability Club", description: "Campus green initiatives and advocacy.",
             category: .volunteer, memberCount: 38, contactEmail: "sustain@uts.edu.au",
             icon: "leaf", isRecruiting: false),
        Club(name: "UTS Chinese Students Association", description: "Cultural events and community.",
             category: .cultural, memberCount: 210, contactEmail: "csa@uts.edu.au",
             icon: "globe.asia.australia", isRecruiting: true),
    ]

    static let defaultProfile = UserProfile(
        fullName: "Alex Student",
        studentID: "12345678",
        email: "alex.student@student.uts.edu.au",
        degree: "Bachelor of Computer Science",
        faculty: "Engineering & IT",
        avatarColor: .blue,
        notifyBookingReminders: true,
        notifyEventAlerts: true,
        notifyClubUpdates: false
    )
}
