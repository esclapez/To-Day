//
//  Todo.swift
//  Today
//
//  Created by Sarah Reichelt on 17/1/2023.
//

import AppKit

struct Todo: Identifiable, Equatable, Hashable, Codable {
  var id = UUID()
  var order: Int
  var title: String
  var createdAt = Date()
  var completedAt: Date?
  var isComplete = false {
    didSet {
      if isComplete != oldValue {
        completedAt = isComplete ? Date() : nil
      }
    }
  }

  var wrappedTitle: String {
    let words = title.components(separatedBy: .whitespaces)
    var wrapped: [String] = [""]
    let maxWidth: CGFloat = 250
    let font = NSFont.menuBarFont(ofSize: 0)
    let attributes: [NSAttributedString.Key: Any] = [.font: font]

    for word in words {
      let index = wrapped.count - 1
      let testString = wrapped[index] + " " + word
      let testAttrib = NSAttributedString(string: testString, attributes: attributes)
      let length = testAttrib.size().width
      if length > maxWidth {
        wrapped.append(word)
      } else {
        wrapped[index] += " " + word
      }
    }

    let wrappedString = wrapped.joined(separator: "\n").trimmingCharacters(in: .whitespaces)
    return wrappedString
  }

  func sortFactor(sortType: Sorts) -> Int {
    if sortType == .dateTime {
      return order + (isComplete ? 10000 : 0)
    } else {
      let firstLetterValue = title.lowercased().first?.unicodeScalars.first?.value ?? 97
      return Int(firstLetterValue) + (isComplete ? 10000 : 0)
    }
  }
}

extension Todo {
  // Custom decoding so todos saved before dates were added still load.
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(UUID.self, forKey: .id)
    order = try container.decode(Int.self, forKey: .order)
    title = try container.decode(String.self, forKey: .title)
    createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete) ?? false
  }
}

extension Todo {
  static var sampleToDos: [Todo] {
    [
      Todo(order: 1, title: "Edit the todos"),
      Todo(order: 2, title: "Add new one"),
      Todo(order: 3, title: "Only for today"),
      Todo(order: 4, title: "Check off progress")
    ]
  }
}
