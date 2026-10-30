//
//  Tag.swift
//  To-Day
//

import SwiftUI

struct Tag: Identifiable, Hashable, Codable {
  var id = UUID()
  var name: String
  var color: TagColor
}

enum TagColor: String, Codable, CaseIterable, Identifiable {
  case red, orange, yellow, green, teal, blue, purple, pink, gray

  var id: String { rawValue }

  var nsColor: NSColor {
    switch self {
    case .red: return .systemRed
    case .orange: return .systemOrange
    case .yellow: return .systemYellow
    case .green: return .systemGreen
    case .teal: return .systemTeal
    case .blue: return .systemBlue
    case .purple: return .systemPurple
    case .pink: return .systemPink
    case .gray: return .systemGray
    }
  }

  var color: Color {
    Color(nsColor: nsColor)
  }

  var name: LocalizedStringKey {
    switch self {
    case .red: return "Red"
    case .orange: return "Orange"
    case .yellow: return "Yellow"
    case .green: return "Green"
    case .teal: return "Teal"
    case .blue: return "Blue"
    case .purple: return "Purple"
    case .pink: return "Pink"
    case .gray: return "Gray"
    }
  }

  // Menus draw SwiftUI images as monochrome templates, so the menu bar menu
  // uses a pre-drawn, non-template dot to keep the tag color.
  var menuImage: NSImage {
    let image = NSImage(size: NSSize(width: 10, height: 10), flipped: false) { rect in
      nsColor.setFill()
      NSBezierPath(ovalIn: rect.insetBy(dx: 0.5, dy: 0.5)).fill()
      return true
    }
    image.isTemplate = false
    return image
  }
}

/// A small colored dot with the tag's name, for use in windows.
struct TagBadge: View {
  let tag: Tag

  var body: some View {
    HStack(spacing: 4) {
      Circle()
        .fill(tag.color.color)
        .frame(width: 8, height: 8)
      Text(tag.name)
    }
    .accessibilityElement(children: .combine)
  }
}
