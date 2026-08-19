//
//  ContentView.swift
//  Writing
//
//  Created by Aulia Agus on 07/08/26.
//

import SwiftUI

enum Route {
    case home
    case writing
    case animation
    case profile
    case read
    case bookmarks
}

struct ContentView: View {
    @StateObject private var store = AppStore()
    @State private var showSplash = true
    @State private var route: Route = .home

    var body: some View {
        ZStack {
            switch route {
            case .home:
                HomeView(route: $route)
            case .writing:
                WritingView(route: $route)
            case .animation:
                TransitionAnimationView(route: $route)
            case .profile:
                ProfileView(route: $route)
            case .read:
                ReadView(route: $route)
            case .bookmarks:
                BookmarkView(route: $route)
            }
        }
        .environmentObject(store)
        .overlay {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeInOut(duration: 0.4)) {
                showSplash = false
            }
        }
    }
}

#Preview {
    ContentView()
}
