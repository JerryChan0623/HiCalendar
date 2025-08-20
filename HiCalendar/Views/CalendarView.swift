//
//  CalendarView.swift
//  HiCalendar
//
//  Created on 2024. Cute Calendar AI 日历页
//

import SwiftUI

struct CalendarView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("日历页")
                    .font(BrandFont.displayMedium)
                    .foregroundColor(BrandColor.neutral700)
                
                Text("月/周/日视图切换，自定义日历组件")
                    .font(BrandFont.bodyMedium)
                    .foregroundColor(BrandColor.neutral500)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BrandSolid.background.ignoresSafeArea())
            .navigationTitle("日历")
        }
    }
}

#Preview {
    CalendarView()
}

