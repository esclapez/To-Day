//
//  ArchivedWeek.swift
//  To-Day
//

import Foundation

struct ArchivedWeek: Identifiable, Codable {
  var weekStart: Date
  var todos: [Todo]

  var id: Date { weekStart }

  var completedCount: Int {
    todos.filter { $0.isComplete }.count
  }

  var weekEnd: Date {
    Calendar.current.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
  }
}
