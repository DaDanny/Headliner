//
//  PersonalInfoView.swift
//  Headliner
//
//  Displays current personal information (location, time, weather) that will be used in overlays.
//

import SwiftUI

/// A reusable view for displaying current personal information
struct PersonalInfoView: View {
    @State private var currentInfo: PersonalInfo?
    @State private var refreshTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                
                Text("Current Data")
                    .font(.system(size: 14, weight: .semibold))
                
                Spacer()
                
                // Live indicator
                if currentInfo != nil {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("Live")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Data display
            if let info = currentInfo {
                VStack(alignment: .leading, spacing: 8) {
                    // Location
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        
                        Text(info.city ?? "Location not available")
                            .font(.system(size: 12))
                            .foregroundColor(info.city != nil ? .primary : .secondary)
                        
                        Spacer()
                    }
                    
                    // Time
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 16)
                        
                        Text(info.localTime ?? "Time not available")
                            .font(.system(size: 12))
                            .foregroundColor(info.localTime != nil ? .primary : .secondary)
                        
                        Spacer()
                    }
                    
                    // Weather
                    HStack(spacing: 8) {
                        if let emoji = info.weatherEmoji {
                            Text(emoji)
                                .font(.system(size: 11))
                                .frame(width: 16)
                        } else {
                            Image(systemName: "cloud.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 16)
                        }
                        
                        Text(info.weatherText ?? "Weather not available")
                            .font(.system(size: 12))
                            .foregroundColor(info.weatherText != nil ? .primary : .secondary)
                        
                        Spacer()
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                )
                
                Text("This data appears in your camera overlay")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .italic()
                
            } else {
                // No data yet
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    
                    Text("No personal data available yet")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 0.5)
                        )
                )
                
                Text("Enable location access to see your data")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        )
        .onAppear {
            loadPersonalInfo()
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadPersonalInfo() {
        guard let userDefaults = UserDefaults(suiteName: Identifiers.appGroup),
              let data = userDefaults.data(forKey: "overlay.personalInfo.v1"),
              let info = try? JSONDecoder().decode(PersonalInfo.self, from: data) else {
            currentInfo = nil
            return
        }
        
        currentInfo = info
        logger.debug("PersonalInfoView: Loaded - city: \(info.city ?? "nil"), weather: \(info.weatherEmoji ?? "nil")")
    }
    
    private func startRefreshTimer() {
        // Refresh every 5 seconds to show latest data
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            loadPersonalInfo()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Preview

#if DEBUG
struct PersonalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalInfoView()
            .frame(width: 400)
            .padding()
    }
}
#endif
