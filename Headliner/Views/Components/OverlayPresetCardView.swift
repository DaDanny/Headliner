//
//  OverlayPresetCardView.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

// MARK: - Reusable Overlay Preset Definitions

enum OverlayPresetOption: String, CaseIterable, Equatable {
  case professional = "professional"
  case personal = "personal"
  case clean = "clean"
  case creative = "creative"

  var title: String {
    switch self {
    case .professional: return "Professional"
    case .personal: return "Personal"
    case .creative: return "Creative"
    case .clean: return "Clean"
    }
  }

  var subtitle: String {
    switch self {
    case .professional: return "Clean name badge"
    case .personal: return "Name • location"
    case .creative: return "(Coming Soon)"
    case .clean: return "No overlay"
    }
  }

  var icon: String {
    switch self {
    case .professional: return "person.text.rectangle"
    case .personal: return "location.north.circle"
    case .creative: return "paintbrush"
    case .clean: return "camera"
    }
  }
}

// MARK: - Reusable Overlay Preset Card

struct OverlayPresetCardView: View {
  let preset: OverlayPresetOption
  let isSelected: Bool
  let action: () -> Void
  
  // Optional sizing customization
  var cardSize: CGSize = CGSize(width: 200, height: 112)
  var showLabels: Bool = true
  
  // Check if preset is disabled (coming soon)
  private var isDisabled: Bool {
    preset == .creative
  }

  @Environment(\.colorScheme) private var scheme

  var body: some View {
    Button(action: isDisabled ? {} : action) {
      VStack(spacing: showLabels ? 10 : 0) {
        // --- Camera preview mock ---
        ZStack {
          // video frame
          RoundedRectangle(cornerRadius: 14)
            .fill(LinearGradient(
              colors: [Color.black.opacity(0.9), Color.black.opacity(0.7)],
              startPoint: .topLeading, endPoint: .bottomTrailing
            ))
            .overlay(
              RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 10, y: 6)

          // subtle person silhouette
          Image(systemName: "person.fill")
            .font(.system(size: cardSize.width * 0.28, weight: .regular))
            .foregroundStyle(.white.opacity(0.14))
            .offset(y: 4)

          // overlay mock shapes for each preset
          overlayMocks
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .overlay(alignment: .topTrailing) {
          // Coming soon indicator for disabled presets
          if isDisabled {
            VStack {
              HStack {
                Spacer()
                Text("Coming Soon")
                  .font(.caption2.weight(.medium))
                  .foregroundStyle(.white)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(.orange.opacity(0.8), in: Capsule())
              }
              Spacer()
            }
            .padding(8)
          }
        }
        .overlay(
          // selection ring
          RoundedRectangle(cornerRadius: 16)
            .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        )

        // labels (optional)
        if showLabels {
          VStack(spacing: 2) {
            Text(preset.title)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(.primary)
            Text(preset.subtitle)
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: cardSize.width)
        }
      }
      .padding(12)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(nsColor: .controlBackgroundColor))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(.white.opacity(scheme == .dark ? 0.05 : 0.12))
      )
      .shadow(color: .black.opacity(isSelected ? 0.25 : 0.15), radius: isSelected ? 14 : 8, y: 6)
      .scaleEffect(isSelected ? 1.02 : 1.0)
      .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isSelected)
      .contentShape(RoundedRectangle(cornerRadius: 16))
      .opacity(isDisabled ? 0.6 : 1.0)
      .grayscale(isDisabled ? 0.3 : 0.0)
      .overlay(alignment: .topTrailing) {
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .padding(6)
            .background(.ultraThinMaterial, in: Circle())
            .offset(x: 2, y: -2)
        }
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(preset.title) overlay")
  }

  // MARK: - Mock overlay drawings
  @ViewBuilder private var overlayMocks: some View {
    switch preset {
    case .clean:
      // No overlay mock - clean camera feed
      EmptyView()

    case .professional:
      // Lower-third badge + small pill
      VStack {
        Spacer()
        HStack {
          Spacer()
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.accentColor)
            .frame(width: cardSize.width * 0.55, height: cardSize.height * 0.18)
            .overlay(
              HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.fill")
                  .font(.system(size: cardSize.width * 0.06))
                  .foregroundStyle(.white.opacity(0.9))
                RoundedRectangle(cornerRadius: 4)
                  .fill(.white.opacity(0.6))
                  .frame(width: cardSize.width * 0.3, height: cardSize.height * 0.07)
              }
            )
          Spacer()
        }
        .padding(.bottom, 8)
      }

    case .personal:
      VStack {
        // top pill slightly inset from left
        HStack {
          Capsule().fill(.white.opacity(0.85))
            .frame(width: cardSize.width * 0.39, height: cardSize.height * 0.14)
            .overlay(
              HStack(spacing: 6) {
                Image(systemName: "location.fill")
                  .font(.system(size: cardSize.width * 0.045))
                RoundedRectangle(cornerRadius: 3)
                  .fill(.black.opacity(0.5))
                  .frame(width: cardSize.width * 0.2, height: cardSize.height * 0.07)
              }
              .foregroundStyle(.black.opacity(0.75))
            )
          Spacer()
        }
        .padding(.top, 8)
        .padding(.leading, 12)

        Spacer()

        // bottom badge centered
        HStack {
          Spacer()
          RoundedRectangle(cornerRadius: 7)
            .fill(Color.accentColor)
            .frame(width: cardSize.width * 0.55, height: cardSize.height * 0.16)
            .overlay(
              RoundedRectangle(cornerRadius: 3)
                .fill(.white.opacity(0.6))
                .frame(width: cardSize.width * 0.32, height: cardSize.height * 0.07)
            )
          Spacer()
        }
        .padding(.bottom, 8)
      }

    case .creative:
      ZStack {
        // corner ribbons
        Rectangle()
          .fill(Color.accentColor.opacity(0.9))
          .frame(width: cardSize.width * 0.35, height: cardSize.height * 0.09)
          .rotationEffect(.degrees(-18))
          .offset(x: -cardSize.width * 0.25, y: -cardSize.height * 0.3)
          .clipShape(RoundedRectangle(cornerRadius: 4))

        Rectangle()
          .fill(Color.purple.opacity(0.9))
          .frame(width: cardSize.width * 0.35, height: cardSize.height * 0.09)
          .rotationEffect(.degrees(18))
          .offset(x: cardSize.width * 0.25, y: cardSize.height * 0.3)
          .clipShape(RoundedRectangle(cornerRadius: 4))

        // floating info tag centered horizontally
        VStack {
          Spacer()
          HStack {
            Spacer()
            RoundedRectangle(cornerRadius: 8)
              .fill(.white.opacity(0.85))
              .frame(width: cardSize.width * 0.45, height: cardSize.height * 0.2)
              .overlay(
                HStack(spacing: 6) {
                  Image(systemName: "sparkles")
                    .font(.system(size: cardSize.width * 0.05))
                  RoundedRectangle(cornerRadius: 3)
                    .fill(.black.opacity(0.5))
                    .frame(width: cardSize.width * 0.24, height: cardSize.height * 0.07)
                }
                .foregroundStyle(.black.opacity(0.75))
              )
            Spacer()
          }
          Spacer().frame(height: 24) // control vertical offset
        }
      }
    }
  }
}

// MARK: - Preset Card Grid View

struct OverlayPresetGrid: View {
  let selectedPresetId: String
  let onPresetSelected: (String) -> Void
  
  // Layout customization
  var columns: Int = 4
  var cardSize: CGSize = CGSize(width: 160, height: 90)
  var spacing: CGFloat = 16
  var showLabels: Bool = true
  
  // Filter out disabled presets if needed
  var availablePresets: [OverlayPresetOption] {
    OverlayPresetOption.allCases.filter { $0 != .creative }
  }
  
  private var gridColumns: [GridItem] {
    Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)
  }
  
  var body: some View {
    LazyVGrid(columns: gridColumns, spacing: spacing) {
      ForEach(availablePresets, id: \.self) { preset in
        OverlayPresetCardView(
          preset: preset,
          isSelected: selectedPresetId == preset.rawValue,
          action: {
            onPresetSelected(preset.rawValue)
          },
          cardSize: cardSize,
          showLabels: showLabels
        )
      }
    }
  }
}

// MARK: - Preview

#if DEBUG
struct OverlayPresetCardView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      // Individual cards (including disabled creative)
      HStack(spacing: 16) {
        ForEach(OverlayPresetOption.allCases, id: \.self) { preset in
          OverlayPresetCardView(
            preset: preset,
            isSelected: preset == .professional,
            action: {}
          )
        }
      }
      .previewDisplayName("Individual Cards (Including Disabled)")
      
      // Grid layout (smaller cards for settings - excludes disabled)
      OverlayPresetGrid(
        selectedPresetId: "personal",
        onPresetSelected: { _ in },
        cardSize: CGSize(width: 140, height: 80),
        showLabels: false
      )
      .previewDisplayName("Settings Grid Layout (Excludes Disabled)")
    }
    .padding()
    .background(Color(NSColor.windowBackgroundColor))
  }
}
#endif
