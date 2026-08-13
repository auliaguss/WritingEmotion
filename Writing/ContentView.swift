//
//  ContentView.swift
//  Writing
//
//  Created by Aulia Agus on 07/08/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = LetterStore()

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "folder.fill") }
        }
        .environmentObject(store)
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
}
