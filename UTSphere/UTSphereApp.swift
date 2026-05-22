// UTSphere — UTSphereApp.swift
// Drop this into your Xcode project as the @main entry point.
// AppViewModel is created once here and injected into the
// entire view hierarchy via .environmentObject — no prop drilling.

import SwiftUI

@main
struct UTSphereApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(viewModel)
        }
    }
}
