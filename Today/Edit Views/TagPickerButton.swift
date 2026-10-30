//
//  TagPickerButton.swift
//  To-Day
//

import SwiftUI

struct TagPickerButton: View {
  @EnvironmentObject var appState: AppState
  @Binding var todo: Todo
  @State private var showingPicker = false

  var body: some View {
    Button {
      showingPicker = true
    } label: {
      if let tag = appState.tag(for: todo) {
        Circle()
          .fill(tag.color.color)
          .frame(width: 12, height: 12)
      } else {
        Image(systemName: "tag")
          .foregroundColor(.secondary)
      }
    }
    .buttonStyle(.plain)
    .frame(width: 16)
    .help(appState.tag(for: todo)?.name ?? String(localized: "No Tag"))
    .accessibilityLabel(tagAccessibilityLabel)
    .popover(isPresented: $showingPicker, arrowEdge: .bottom) {
      tagList
    }
  }

  var tagAccessibilityLabel: Text {
    if let tag = appState.tag(for: todo) {
      return Text("Tag: \(tag.name)")
    }
    return Text("No Tag")
  }

  var tagList: some View {
    VStack(alignment: .leading, spacing: 2) {
      tagRow(isSelected: todo.tagID == nil, tagID: nil) {
        Text("No Tag")
      }

      ForEach(appState.tags) { tag in
        tagRow(isSelected: todo.tagID == tag.id, tagID: tag.id) {
          TagBadge(tag: tag)
        }
      }

      if appState.tags.isEmpty {
        Text("Use Tags… below to create tags.")
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.horizontal, 6)
          .padding(.top, 4)
      }
    }
    .padding(8)
    .frame(minWidth: 160, alignment: .leading)
  }

  func tagRow<Content: View>(isSelected: Bool, tagID: UUID?, @ViewBuilder content: () -> Content) -> some View {
    Button {
      todo.tagID = tagID
      showingPicker = false
    } label: {
      HStack {
        content()
        Spacer()
        if isSelected {
          Image(systemName: "checkmark")
        }
      }
      .padding(.horizontal, 6)
      .padding(.vertical, 3)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
