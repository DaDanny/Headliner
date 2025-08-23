//
//  CameraSelector.swift
//  Headliner
//
//  Created by AI Assistant on 8/2/25.
//

import SwiftUI

// MARK: - CameraSelector

struct CameraSelector: View {
  @ObservedObject var appState: AppState
  @State private var open = false
  @State private var hover = false

  // Get the running state from AppState camera status
  private var isVirtualCameraRunning: Bool { 
    appState.cameraStatus.isRunning
  }

  private var selectedCamera: CameraDevice? {
    appState.availableCameras.first { $0.id == appState.selectedCameraID }
  }

  public var body: some View {
    Button {
      open.toggle()
    } label: {
      CameraSelectorLabel(
        selected: selectedCamera,
        isRunning: isVirtualCameraRunning
      )
      .scaleEffect(hover ? 1.01 : 1.0)
    }
    .buttonStyle(.plain)
    .onHover { hover = $0 }
    .popover(isPresented: $open, arrowEdge: .bottom) {
      CameraSelectorPopoverContent(
        appState: appState,
        selectedCamera: selectedCamera,
        close: { open = false }
      )
    }
    .keyboardShortcut("C", modifiers: [.command, .shift]) // ⌘⇧C opens the selector
    .accessibilityLabel("Camera selector")
    .accessibilityHint("Choose your input camera for Headliner")
  }
}

// MARK: - Label (Loom‑style pill)

private struct CameraSelectorLabel: View {
  let selected: CameraDevice?
  let isRunning: Bool

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: symbol(for: selected))
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Color.accentColor)
        .frame(width: 20)

      VStack(alignment: .leading, spacing: 1) {
        Text(selected?.name ?? "No Camera")
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.primary)

        Text(selected?.deviceType ?? "Select a camera")
          .font(.system(size: 12))
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 8)

      // Status badge like Loom's "On/Off"
      Text(isRunning ? "On" : "Off")
        .font(.system(size: 11, weight: .semibold))
        .padding(.vertical, 3)
        .padding(.horizontal, 8)
        .background(
          Capsule(style: .continuous)
            .fill(isRunning ? Color.green.opacity(0.18) : Color.secondary.opacity(0.12))
        )
        .foregroundStyle(isRunning ? .green : .secondary)

      Image(systemName: "chevron.down")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(.secondary)
    }
    .padding(.vertical, 10)
    .padding(.horizontal, 14)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(.white.opacity(0.08))
    )
    .contentShape(Rectangle())
  }

  private func symbol(for cam: CameraDevice?) -> String {
    guard let cam else { return "video.slash.fill" }
    if cam.deviceType.contains("iPhone") || cam.deviceType.contains("Continuity") { return "iphone" }
    if cam.deviceType.contains("External") { return "camera.on.rectangle" }
    if cam.deviceType.contains("Desk View") { return "camera.macro" }
    return "camera.fill"
  }
}

// MARK: - Popover content

private struct CameraSelectorPopoverContent: View {
  @ObservedObject var appState: AppState
  let selectedCamera: CameraDevice?
  let close: () -> Void

  @State private var hoveringID: String?
  @Environment(\.colorScheme) private var scheme

  // Layout
  private let rowHeight: CGFloat = 40
  private let maxWidth: CGFloat = 340

  var body: some View {
    VStack(spacing: 8) {
      // Header
      HStack {
        Text("Select Camera")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer()
        Button {
          appState.refreshCameras()
        } label: {
          Image(systemName: "arrow.clockwise")
            .font(.system(size: 13, weight: .semibold))
        }
        .buttonStyle(.borderless)
        .help("Refresh Cameras")
      }
      .padding(.horizontal, 10)
      .padding(.top, 10)

      if appState.availableCameras.isEmpty {
        // Empty state
        VStack(spacing: 10) {
          Image(systemName: "camera.slash")
            .font(.system(size: 26, weight: .light))
            .foregroundStyle(.secondary)
          Text("No cameras found")
            .font(.callout.weight(.semibold))
          Text("Connect a camera or try refreshing.")
            .font(.footnote)
            .foregroundStyle(.secondary)
          Button {
            appState.refreshCameras()
          } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
          .padding(.top, 4)
        }
        .frame(width: maxWidth - 20, height: 150)
        .padding(.bottom, 10)
      } else {
        ScrollView {
          VStack(spacing: 6) {
            // Optional "No Camera"
            CameraRow(
              id: "none",
              title: "No Camera",
              subtitle: "Disable input",
              symbol: "video.slash.fill",
              selected: appState.selectedCameraID.isEmpty,
              hoveringID: $hoveringID
            ) {
              appState.selectedCameraID = ""
              close()
            }

            // Sections
            if !builtIn.isEmpty {
              SectionHeader("Built‑in")
              ForEach(builtIn) { cam in
                row(for: cam)
              }
            }
            if !external.isEmpty {
              SectionHeader("External")
              ForEach(external) { cam in
                row(for: cam)
              }
            }
            if !iphone.isEmpty {
              SectionHeader("iPhone")
              ForEach(iphone) { cam in
                row(for: cam)
              }
            }
          }
          .padding(.horizontal, 8)
          .padding(.bottom, 8)
        }
        .frame(height: min(380, CGFloat(appState.availableCameras.count + 6) * (rowHeight * 0.9)))
      }
    }
    .frame(width: maxWidth)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(.white.opacity(scheme == .dark ? 0.08 : 0.12))
    )
    .padding(6)
  }

  private func row(for cam: CameraDevice) -> some View {
    CameraRow(
      id: cam.id,
      title: cam.name,
      subtitle: cam.deviceType,
      symbol: symbol(for: cam),
      selected: cam.id == appState.selectedCameraID,
      hoveringID: $hoveringID
    ) {
      appState.selectCamera(cam)
      close()
    }
  }

  // Grouping
  private var builtIn: [CameraDevice] {
    appState.availableCameras.filter { $0.deviceType.localizedCaseInsensitiveContains("built") }
  }
  private var external: [CameraDevice] {
    appState.availableCameras.filter { $0.deviceType.localizedCaseInsensitiveContains("external") }
  }
  private var iphone: [CameraDevice] {
    appState.availableCameras.filter {
      $0.deviceType.localizedCaseInsensitiveContains("iphone")
      || $0.deviceType.localizedCaseInsensitiveContains("continuity")
    }
  }

  private func symbol(for cam: CameraDevice) -> String {
    if cam.deviceType.contains("iPhone") || cam.deviceType.contains("Continuity") { return "iphone" }
    if cam.deviceType.contains("External") { return "camera.on.rectangle" }
    if cam.deviceType.contains("Desk View") { return "camera.macro" }
    return "camera.fill"
  }
}

// MARK: - Row + Section header

private struct CameraRow: View {
  let id: String
  let title: String
  let subtitle: String
  let symbol: String
  let selected: Bool
  @Binding var hoveringID: String?
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: symbol)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.secondary)
          .frame(width: 20)

        VStack(alignment: .leading, spacing: 0) {
          Text(title).font(.system(size: 14, weight: .medium))
          Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
        }

        Spacer()

        if selected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(Color.accentColor)
        }
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(hoveringID == id ? Color.primary.opacity(0.06) : Color.clear)
      )
    }
    .buttonStyle(.plain)
    .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .onHover { hoveringID = $0 ? id : nil }
    .accessibilityLabel("\(title), \(selected ? "selected" : "not selected")")
  }
}

private struct SectionHeader: View {
  let text: String
  init(_ text: String) { self.text = text }
  var body: some View {
    HStack {
      Text(text.uppercased())
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(.secondary)
      Spacer()
    }
    .padding(.horizontal, 10)
    .padding(.top, 8)
  }
}

// MARK: - PREVIEWS

#if DEBUG
struct CameraSelector_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      CameraSelector(appState: PreviewAppState())
        .padding()
        .frame(width: 420)
        .background(Color.gray.opacity(0.1))
        .previewDisplayName("Empty / Off")

      CameraSelector(appState: PreviewAppState(
        availableCameras: [
          CameraDevice(id: "built-in", name: "Built-in Camera", deviceType: "Built-in Camera"),
          CameraDevice(id: "external", name: "Logitech C920", deviceType: "External Camera"),
          CameraDevice(id: "iphone", name: "iPhone Camera", deviceType: "iPhone / Continuity")
        ],
        selectedCameraID: "built-in"
      ))
      .padding()
      .frame(width: 420)
      .background(Color.gray.opacity(0.1))
      .previewDisplayName("Selected / On")
    }
  }
}

// Preview-only AppState for CameraSelector
private class PreviewAppState: AppState {
  init(
    availableCameras: [CameraDevice] = [],
    selectedCameraID: String = ""
  ) {
    super.init(
      systemExtensionManager: SystemExtensionRequestManager(logText: "Preview"),
      propertyManager: CustomPropertyManager(),
      outputImageManager: OutputImageManager()
    )
    self.availableCameras = availableCameras
    self.selectedCameraID = selectedCameraID
  }
}
#endif
