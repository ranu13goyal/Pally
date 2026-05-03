//
//  ContentView.swift
//  iPal
//
//  Created by Ranu on 18/04/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Feed", systemImage: "newspaper")
                }
            
            LearningHomeView()
                .tabItem {
                    Label("Learn", systemImage: "brain.head.profile")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
        }
    }
}
