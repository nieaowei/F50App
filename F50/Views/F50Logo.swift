//
//  F50AppIcon.swift
//  F50
//
//  Created by Nekilc on 2025/11/4.
//  App Icon Design Reference
//

import SwiftUI

struct F50AppIcon_Preview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Design - macOS")
                .font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .fill(.white.opacity(0.15))
                    .frame(width: 70, height: 70)
                    .offset(y: -5)

                Image(systemName: "wifi.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.white)
                    .offset(y: -8)

                Text("F")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .offset(y: 18)
            }
            .frame(width: 128, height: 128)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .padding()
    }
}

struct F50Logo_Mark: View {
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: size * 0.7, height: size * 0.7)
                .offset(y: -size * 0.05)

            Image(systemName: "wifi.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .frame(width: size * 0.5, height: size * 0.5)
                .offset(y: -size * 0.08)

            Text("F")
                .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .offset(y: size * 0.2)
        }
        .frame(width: size, height: size)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    F50Logo_Mark(size: 100)
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color.black.opacity(0.1))
}