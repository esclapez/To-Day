//
//  TagsEditor.swift
//  To-Day
//

import SwiftUI

struct TagsEditor: View {
  @EnvironmentObject var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @State private var newTagName = ""
  @State private var newTagColor = TagColor.blue

  var body: some View {
    VStack(spacing: 0) {
      Form {
        Section("Tags") {
          if appState.tags.isEmpty {
            Text("No tags yet.")
              .foregroundColor(.secondary)
          }

          ForEach($appState.tags) { $tag in
            HStack {
              TextField("", text: $tag.name)
                .labelsHidden()

              ColorPalette(selection: $tag.color)

              Button {
                appState.deleteTag(tag)
              } label: {
                Image(systemName: "trash")
                  .foregroundColor(.red)
              }
              .buttonStyle(.plain)
              .accessibilityLabel("Delete tag \(tag.name)")
            }
          }
        }

        Section("Enter new tag and press Return:") {
          HStack {
            TextField("", text: $newTagName)
              .labelsHidden()
              .accessibilityLabel("Enter new tag and press Return")
              .onSubmit(addTag)

            ColorPalette(selection: $newTagColor)
          }
        }
      }
      .formStyle(.grouped)
      .textFieldStyle(.squareBorder)

      HStack {
        Spacer()
        Button("Done") {
          dismiss()
        }
        .keyboardShortcut(.defaultAction)
      }
      .padding([.horizontal, .bottom], 12)
    }
    .frame(width: 460, height: 380)
  }

  func addTag() {
    let name = newTagName.trimmingCharacters(in: .whitespaces)
    guard !name.isEmpty else { return }
    appState.createTag(name: name, color: newTagColor)
    newTagName = ""
  }
}

struct ColorPalette: View {
  @Binding var selection: TagColor

  var body: some View {
    HStack(spacing: 4) {
      ForEach(TagColor.allCases) { tagColor in
        Button {
          selection = tagColor
        } label: {
          Circle()
            .fill(tagColor.color)
            .frame(width: 14, height: 14)
            .overlay {
              if selection == tagColor {
                Circle()
                  .strokeBorder(Color.primary, lineWidth: 2)
                  .frame(width: 18, height: 18)
              }
            }
            .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .help(Text(tagColor.name))
        .accessibilityLabel(Text(tagColor.name))
        .accessibilityAddTraits(selection == tagColor ? .isSelected : [])
      }
    }
  }
}

struct TagsEditor_Previews: PreviewProvider {
  static var previews: some View {
    TagsEditor()
      .environmentObject(AppState())
  }
}
