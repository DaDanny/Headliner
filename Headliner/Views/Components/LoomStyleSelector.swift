//
//  LoomStyleSelector.swift
//  Headliner
//
//  Created by AI Assistant on 8/22/25.
//

import SwiftUI

// MARK: - LoomStyleSelector

/// A reusable Loom-style selector component with beautiful pill design
struct LoomStyleSelector<Item: Identifiable & Hashable, DropdownContent: View>: View {
  // Configuration
  let title: String
  let items: [Item]?
  let selectedItem: Item?
  let onSelectionChange: ((Item?) -> Void)?
  let onTap: (() -> Void)?
  
  // Display customization
  let itemIcon: (Item?) -> String
  let itemTitle: (Item?) -> String  
  let itemSubtitle: (Item?) -> String?
  let statusBadge: (Item?) -> (text: String, color: Color)?
  let chevronIcon: String
  let dropdownContent: () -> DropdownContent
  
  // State
  @State private var isOpen = false
  @State private var isHovered = false
  
  // Dropdown initializer (for camera selection)
  init(
    title: String,
    items: [Item],
    selectedItem: Item?,
    onSelectionChange: @escaping (Item?) -> Void,
    itemIcon: @escaping (Item?) -> String,
    itemTitle: @escaping (Item?) -> String,
    itemSubtitle: @escaping (Item?) -> String?,
    statusBadge: @escaping (Item?) -> (text: String, color: Color)? = { _ in nil },
    chevronIcon: String = "chevron.down",
    @ViewBuilder dropdownContent: @escaping () -> DropdownContent = { EmptyView() }
  ) {
    self.title = title
    self.items = items
    self.selectedItem = selectedItem
    self.onSelectionChange = onSelectionChange
    self.onTap = nil
    self.itemIcon = itemIcon
    self.itemTitle = itemTitle
    self.itemSubtitle = itemSubtitle
    self.statusBadge = statusBadge
    self.chevronIcon = chevronIcon
    self.dropdownContent = dropdownContent
  }
  
  // Simple action initializer (for overlay navigation)
  init(
    title: String,
    selectedTitle: String,
    selectedSubtitle: String?,
    icon: String,
    statusBadge: (text: String, color: Color)? = nil,
    chevronIcon: String = "chevron.right",
    onTap: @escaping () -> Void
  ) where DropdownContent == EmptyView {
    self.title = title
    self.items = nil
    self.selectedItem = nil
    self.onSelectionChange = nil
    self.onTap = onTap
    self.itemIcon = { _ in icon }
    self.itemTitle = { _ in selectedTitle }
    self.itemSubtitle = { _ in selectedSubtitle }
    self.statusBadge = { _ in statusBadge }
    self.chevronIcon = chevronIcon
    self.dropdownContent = { EmptyView() }
  }
  
  var body: some View {
    Button {
      if let items = items, !items.isEmpty {
        // Dropdown behavior for camera selection
        isOpen.toggle()
      } else if let onTap = onTap {
        // Direct action for navigation
        onTap()
      }
    } label: {
      LoomStyleSelectorLabel(
        icon: itemIcon(selectedItem),
        title: itemTitle(selectedItem),
        subtitle: itemSubtitle(selectedItem),
        statusBadge: statusBadge(selectedItem),
        chevronIcon: chevronIcon
      )
      .scaleEffect(isHovered ? 1.01 : 1.0)
      .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
    .buttonStyle(.plain)
    .onHover { isHovered = $0 }
    .popover(isPresented: $isOpen, arrowEdge: .bottom) {
      // Only show popover if we have items (dropdown behavior)
      if let items = items {
        LoomStyleDropdown(
          title: title,
          items: items,
          selectedItem: selectedItem,
          onSelectionChange: { item in
            onSelectionChange?(item)
            isOpen = false
          },
          itemIcon: itemIcon,
          itemTitle: itemTitle,
          itemSubtitle: itemSubtitle,
          customContent: dropdownContent
        )
      }
    }
    .accessibilityLabel("\(title) selector")
    .accessibilityHint("Choose your \(title.lowercased())")
  }
}

// MARK: - LoomStyleSelectorLabel

/// The beautiful pill-shaped label that matches CameraSelector's design
private struct LoomStyleSelectorLabel: View {
  let icon: String
  let title: String
  let subtitle: String?
  let statusBadge: (text: String, color: Color)?
  let chevronIcon: String
  
  var body: some View {
    HStack(spacing: 10) {
      // Icon
      Image(systemName: icon)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(Color.accentColor)
        .frame(width: 20)
      
      // Content
      VStack(alignment: .leading, spacing: 1) {
        Text(title)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.primary)
          .padding(.vertical, 6)
        
//        if let subtitle = subtitle {
//          Text(subtitle)
//            .font(.system(size: 12))
//            .foregroundStyle(.secondary)
//        }
      }
      
      Spacer(minLength: 8)
      
      // Status badge (optional)
      if let badge = statusBadge {
        Text(badge.text)
          .font(.system(size: 11, weight: .semibold))
          .padding(.vertical, 3)
          .padding(.horizontal, 8)
          .background(
            Capsule(style: .continuous)
              .fill(badge.color.opacity(0.18))
          )
          .foregroundStyle(badge.color)
      }
      
      // Chevron
      Image(systemName: chevronIcon)
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
}

// MARK: - LoomStyleDropdown

/// The dropdown popover content that matches CameraSelector's design
private struct LoomStyleDropdown<Item: Identifiable & Hashable, CustomContent: View>: View {
  let title: String
  let items: [Item]
  let selectedItem: Item?
  let onSelectionChange: (Item?) -> Void
  let itemIcon: (Item?) -> String
  let itemTitle: (Item?) -> String
  let itemSubtitle: (Item?) -> String?
  let customContent: () -> CustomContent
  
  @State private var hoveringID: String?
  @Environment(\.colorScheme) private var scheme
  
  // Layout
  private let rowHeight: CGFloat = 40
  private let maxWidth: CGFloat = 340
  
  var body: some View {
    VStack(spacing: 8) {
      // Header
      HStack {
        Text("Select \(title)")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer()
      }
      .padding(.horizontal, 10)
      .padding(.top, 10)
      
      if items.isEmpty {
        // Empty state
        VStack(spacing: 10) {
          Image(systemName: "questionmark.circle")
            .font(.system(size: 26, weight: .light))
            .foregroundStyle(.secondary)
          Text("No items found")
            .font(.callout.weight(.semibold))
          Text("No \(title.lowercased()) available.")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .frame(width: maxWidth - 20, height: 150)
        .padding(.bottom, 10)
      } else {
        ScrollView {
          VStack(spacing: 6) {
            // Custom content (if provided)
            customContent()
            
            // Items
            ForEach(items, id: \.id) { item in
              LoomStyleDropdownRow(
                id: "\(item.id)",
                title: itemTitle(item),
                subtitle: itemSubtitle(item),
                icon: itemIcon(item),
                selected: selectedItem?.id == item.id,
                hoveringID: $hoveringID
              ) {
                onSelectionChange(item)
              }
            }
          }
          .padding(.horizontal, 8)
          .padding(.bottom, 8)
        }
        .frame(height: min(380, CGFloat(items.count + 2) * (rowHeight * 0.9)))
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
}

// MARK: - LoomStyleDropdownRow

/// Individual row in the dropdown that matches CameraSelector's row design
private struct LoomStyleDropdownRow: View {
  let id: String
  let title: String
  let subtitle: String?
  let icon: String
  let selected: Bool
  @Binding var hoveringID: String?
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Image(systemName: icon)
          .font(.system(size: 15, weight: .semibold))
          .foregroundStyle(.secondary)
          .frame(width: 20)
        
        VStack(alignment: .leading, spacing: 0) {
          Text(title).font(.system(size: 14, weight: .medium))
          if let subtitle = subtitle {
            Text(subtitle).font(.system(size: 11)).foregroundStyle(.secondary)
          }
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

// MARK: - PREVIEWS

#if DEBUG
struct LoomStyleSelector_Previews: PreviewProvider {
  static var previews: some View {
    // Minimal preview for the component
    LoomStyleSelectorLabel(
      icon: "camera.fill",
      title: "Built-in Camera",
      subtitle: "Built-in Camera",
      statusBadge: ("On", .green),
      chevronIcon: "chevron.down"
    )
    .padding()
    .frame(width: 420)
    .background(Color.gray.opacity(0.1))
    .previewDisplayName("Loom Style Selector")
  }
}
#endif
