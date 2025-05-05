//
//  WeatherCardView.swift
//  WeatherApp
//
//  Created by Stanley Yu on 3/29/25.
//

import SwiftUI

struct WeatherCardView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                Text(title)
                    .font(.title2)
                    .bold()
            }

        content
        }
        .padding()
        .background(Color.white.opacity(0.3))
        .cornerRadius(16)
    }
}



