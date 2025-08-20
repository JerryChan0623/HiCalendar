//
//  EventListView.swift
//  HiCalendar
//
//  Created on 2024. Cute Calendar AI 事件列表页
//

import SwiftUI

struct EventListView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("事件列表页")
                    .font(BrandFont.displayMedium)
                    .foregroundColor(BrandColor.neutral700)
                
                Text("搜索框、日期分组列表、筛选器")
                    .font(BrandFont.bodyMedium)
                    .foregroundColor(BrandColor.neutral500)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BrandSolid.background.ignoresSafeArea())
            .navigationTitle("事件")
        }
    }
}

#Preview {
    EventListView()
}

