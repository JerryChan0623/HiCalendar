//
//  ContentView.swift
//  HiCalendar
//
//  Created by Jerry  on 2025/8/8.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            MainCalendarAIView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundColor(BrandColor.neutral900)
                        }
                    }
                }
        }
        .tint(BrandColor.secondaryRed)
    }
}

#Preview {
    ContentView()
}
