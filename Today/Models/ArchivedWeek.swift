//
//  ArchivedWeek.swift
//  To-Day
//

import Foundation

struct ArchivedWeek: Identifiable, Codable {
  var weekStart: Date
  var todos: [Todo]
  // Snapshot of the tags used that week, so later renames or deletions don't change the archive.
  // Optional because archives written before tags existed don't have it.
  var tags: [Tag]?

  var id: Date { weekStart }

  var completedCount: Int {
    todos.filter { $0.isComplete }.count
  }

  func tag(for todo: Todo) -> Tag? {
    tags?.first { $0.id == todo.tagID }
  }

  var weekEnd: Date {
    Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
  }
}
