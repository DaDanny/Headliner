//
//  OverlaySettingsView.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

struct OverlaySettingsView: View {
  @ObservedObject var appState: AppState
  @State private var localSettings: OverlaySettings
  // Local color picker state removed for now; reintroduce when needed.
  @State private var showingColorPicker = false

  init(appState: AppState) {
    self.appState = appState
    self._localSettings = State(initialValue: appState.overlaySettings)
  }

  var body: some View {
    VStack(spacing: 20) {
      // Header
      HStack {
        Text("Overlay Settings")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.white)

        Spacer()

        Button(action: { appState.isShowingOverlaySettings = false }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.white.opacity(0.6))
            .font(.title2)
        }
        .buttonStyle(PlainButtonStyle())
      }

      ScrollView {
        VStack(spacing: 16) {
          // Enable/Disable Overlays
          GlassmorphicCard {
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Text("Enable Overlays")
                  .font(.headline)
                  .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $localSettings.isEnabled)
                  .scaleEffect(0.8)
              }

              if localSettings.isEnabled {
                Text("Show overlay elements on your video stream for other participants to see.")
                  .font(.caption)
                  .foregroundColor(.white.opacity(0.7))
              }
            }
            .padding()
          }

          if localSettings.isEnabled {
            // User Name Settings
            GlassmorphicCard {
              VStack(alignment: .leading, spacing: 12) {
                HStack {
                  Text("User Name Display")
                    .font(.headline)
                    .foregroundColor(.white)
                  Spacer()
                  Toggle("", isOn: $localSettings.showUserName)
                    .scaleEffect(0.8)
                }

                if localSettings.showUserName {
                  VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                      .font(.subheadline)
                      .foregroundColor(.white.opacity(0.8))

                    TextField("Enter your name", text: $localSettings.userName)
                      .textFieldStyle(RoundedBorderTextFieldStyle())
                      .background(Color.white.opacity(0.1))
                      .cornerRadius(6)
                  }
                }
              }
              .padding()
            }

            // Position Settings
            if localSettings.showUserName {
              GlassmorphicCard {
                VStack(alignment: .leading, spacing: 12) {
                  Text("Position")
                    .font(.headline)
                    .foregroundColor(.white)

                  LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(OverlayPosition.allCases, id: \.self) { position in
                      Button(action: {
                        localSettings.namePosition = position
                      }) {
                        Text(position.displayName)
                          .font(.caption)
                          .foregroundColor(localSettings.namePosition == position ? .black : .white)
                          .padding(.horizontal, 8)
                          .padding(.vertical, 4)
                          .background(
                            localSettings.namePosition == position
                              ? Color.white
                              : Color.white.opacity(0.2)
                          )
                          .cornerRadius(4)
                      }
                      .buttonStyle(PlainButtonStyle())
                    }
                  }
                }
                .padding()
              }

              // Style Settings
              GlassmorphicCard {
                VStack(alignment: .leading, spacing: 16) {
                  Text("Style")
                    .font(.headline)
                    .foregroundColor(.white)

                  // Font Size
                  VStack(alignment: .leading, spacing: 8) {
                    HStack {
                      Text("Font Size")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                      Spacer()
                      Text("\(Int(localSettings.fontSize))pt")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    }

                    Slider(value: $localSettings.fontSize, in: 12 ... 48, step: 2)
                      .accentColor(.white)
                  }

                  // Background Color
                  VStack(alignment: .leading, spacing: 8) {
                    Text("Background Color")
                      .font(.subheadline)
                      .foregroundColor(.white.opacity(0.8))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                      ForEach(OverlayColor.allCases, id: \.self) { color in
                        Button(action: {
                          localSettings.nameBackgroundColor = color
                        }) {
                          RoundedRectangle(cornerRadius: 4)
                            .fill(Color(color.nsColor))
                            .frame(height: 30)
                            .overlay(
                              RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                  localSettings.nameBackgroundColor == color
                                    ? Color.white
                                    : Color.clear,
                                  lineWidth: 2
                                )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                      }
                    }
                  }

                  // Text Color
                  VStack(alignment: .leading, spacing: 8) {
                    Text("Text Color")
                      .font(.subheadline)
                      .foregroundColor(.white.opacity(0.8))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                      ForEach(OverlayColor.allCases, id: \.self) { color in
                        Button(action: {
                          localSettings.nameTextColor = color
                        }) {
                          RoundedRectangle(cornerRadius: 4)
                            .fill(Color(color.nsColor))
                            .frame(height: 30)
                            .overlay(
                              RoundedRectangle(cornerRadius: 4)
                                .stroke(
                                  localSettings.nameTextColor == color
                                    ? Color.white
                                    : Color.clear,
                                  lineWidth: 2
                                )
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                      }
                    }
                  }
                }
                .padding()
              }
            }
          }

          // Action Buttons
          HStack(spacing: 16) {
            ModernButton(
              "Cancel",
              icon: "xmark",
              style: .secondary,
              action: {
                // Reset to original settings
                localSettings = appState.overlaySettings
                appState.isShowingOverlaySettings = false
              }
            )

            ModernButton(
              "Apply",
              icon: "checkmark",
              style: .primary,
              action: {
                appState.updateOverlaySettings(localSettings)
                appState.isShowingOverlaySettings = false
              }
            )
          }
          .padding(.top)
        }
        .padding()
      }
    }
    .padding()
    .background(
      AnimatedBackground()
        .clipShape(RoundedRectangle(cornerRadius: 20))
    )
    .onAppear {
      localSettings = appState.overlaySettings
    }
  }
}

// Intentionally no PreviewProvider to reduce compile surface for tooling.
