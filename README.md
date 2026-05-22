# UTSphere

<p align="center">
  <img src="UTSphere/Assets.xcassets/AppIcon.appiconset/Gemini_Generated_Image_fhcfptfhcfptfhcf-3.png" width="120" alt="UTSphere App Icon"/>
</p>

<p align="center">
  A campus resource booking app for iOS built with SwiftUI.
  Book study rooms, courts and gym slots at UTS, RSVP to events, and manage club memberships.
</p>

<p align="center">
  <a href="https://github.com/vedmchilimbi-arch/UTSphere/tree/main/UTSphere/UTSphere">GitHub Repository</a>
</p>

---

## Features

### Spaces and Courts
- Browse all bookable study rooms, library desks, quiet zones, tennis courts, and gym slots
- See room details: building, floor, capacity, and available equipment
- Tap any resource to open its detail page with a live availability timeline
- The timeline shows green (free) and red (taken) hour slots for the selected day
- Tap a green slot and the booking form opens with the date and time already filled in

### Booking Form
- Pick a date from a graphical calendar (no past dates allowed)
- Choose a start time from 8am to 9pm with a scrollable wheel picker
- Opening time defaults to the next upcoming hour so you never start with an already-passed slot
- Set a duration using a custom stepper (capped by the room's own maximum hours)
- Inline warnings appear for: past times, exceeded duration limits, closing time breaches (10pm cutoff), and double-bookings
- The Confirm button stays disabled until every check passes
- A success banner appears on confirm, then the form auto-dismisses

### Events
- Browse upcoming campus events with categories (Academic, Social, Sport, Career, Workshop)
- See live RSVP counts and remaining spots
- RSVP with one tap; the count updates immediately
- Cancel your RSVP from My Bookings at any time

### Clubs
- Browse all student clubs by category (Academic, Sport, Arts, Tech, Social)
- Search by name or filter by category
- Join or leave with one tap; member count updates live

### My Bookings
- All upcoming room and court bookings in one list, sorted by soonest first
- All your active RSVPs listed below
- Swipe left on any row to cancel with a confirmation step so nothing gets deleted by accident
- Separate empty states if there are no bookings or no RSVPs yet

### Profile
- View and edit your name, student ID, email, and degree
- Pick a custom avatar colour
- Toggle push notifications on or off per category
- Activity summary: total bookings, RSVPs, and clubs joined (read-only)
- Clear all bookings at once from the danger zone (with confirmation)

---

## Architecture

The whole app runs through a single `AppViewModel` class injected at the top level using `@EnvironmentObject`. Every view reads from it or calls a method on it, nothing ever writes to the models directly.

### Why structs everywhere

All models (`Resource`, `Booking`, `StudentEvent`, `Club`, `RSVP`, `UserProfile`) are Swift structs, not classes. Structs are value types, which means every view gets its own independent copy of the data. One view mutating something can't silently affect another view. The only way to change state is to go through a ViewModel method, which keeps the flow predictable.

### Key models

| Type | What it represents |
|------|-------------------|
| `Resource` | A bookable space or court (room, desk, court, gym slot) |
| `ResourceCategory` | Enum: Study Room, Library Desk, Quiet Zone, Court, Gym Slot |
| `Booking` | A single room/court reservation with status (upcoming, cancelled) |
| `StudentEvent` | A campus event with RSVP capacity tracking |
| `Club` | A student club with a live member count |
| `RSVP` | Links a user to an event they signed up for |
| `UserProfile` | The current user's name, ID, degree, avatar and notification settings |

### Conflict detection

Two bookings overlap when one starts before the other ends. The check is:

```swift
b.startDate < newEnd && b.endDate > newStart
```

Cancelled bookings are excluded from this check so a cancelled slot is immediately free again.

---

## File Structure

| File | Owner | What it does |
|------|-------|-------------|
| `Models.swift` | Dev 1 | All data types as structs/enums, plus seed data |
| `AppViewModel.swift` | Dev 1 | All state and business logic (bookings, RSVPs, clubs, profile) |
| `DashboardView.swift` | Dev 2 | TabView with Spaces, Courts, Events, Clubs tabs plus search, filters, and availability timeline |
| `BookingFormView.swift` | Dev 3 | Full booking form with validation, inline warnings, and success banner |
| `MyBookingsView.swift` | Dev 3 | Upcoming bookings and RSVPs with swipe-to-cancel |
| `ProfileView.swift` | Dev 3 | Profile display, editing sheet, settings, and activity summary |

---

## Team

| Developer | Name | Student ID | Branch | Files Owned | Responsibilities |
|-----------|------|------------|--------|-------------|-----------------|
| Dev 1 | Saksham Soni | 25949850 | `feature/data-models` | `Models.swift`, `AppViewModel.swift` | All data models (Resource, Booking, StudentEvent, Club, RSVP, UserProfile), booking conflict detection logic, RSVP and club membership logic |
| Dev 2 | Kumaramanjunath Baleattiguppe Sadashivappa  | 26029785 | `feature/dashboard-ui` | `DashboardView.swift` | TabView layout, Spaces/Courts/Events/Clubs list views, category filters, search, availability timeline |
| Dev 3 | Ved Mohith Chilimbi | 25534948 | `feature/booking-flow` | `BookingFormView.swift`, `MyBookingsView.swift`, `ProfileView.swift` | Booking form with full validation, cancellation flow, profile editing and settings |

---

## Git History

```
main <- feature/data-models (v1)  : Resource + Booking models, core ViewModel
main <- feature/data-models (v2)  : added StudentEvent, Club, RSVP, UserProfile
main <- feature/dashboard-ui (v1) : Spaces tab with basic navigation
main <- feature/dashboard-ui (v2) : all 4 tabs, filters, search, availability timeline
main <- feature/booking-flow (v1) : basic booking form and My Bookings list
main <- feature/booking-flow (v2) : full validation, cancellation flow, Profile view
main    docs: final README + app icon
```

---

## Running It

1. Clone the repo: `git clone https://github.com/saksham172121/UTSsphere.git`
2. Open `UTSphere.xcodeproj` in Xcode 15+
3. Select any iOS 17+ simulator
4. Hit `Cmd+R`

No dependencies to install. No API keys needed. It runs entirely on local in-memory data.
