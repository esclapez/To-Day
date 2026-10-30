//
//  AppState.swift
//  To-Day
//
//  Created by Sarah Reichelt on 20/1/2023.
//

import SwiftUI

// MARK: - Properties

class AppState: ObservableObject {
  @Published var todos: [Todo] = DataStore().loadTodos() {
    didSet {
      debouncedSave()
    }
  }

  @Published var tags: [Tag] = DataStore().loadTags() {
    didSet {
      dataStore.saveTags(tags)
    }
  }

  @AppStorage("completeHandling") var completeHandling = Completes.sortToEnd
  @AppStorage("todoSorting") var todoSorting = Sorts.dateTime
  // Start of the week the current list belongs to, as seconds since 1970 (0 = not set yet).
  @AppStorage("listWeekStart") var listWeekStart: Double = 0

  var dataStore = DataStore()
  var saveTask: DispatchWorkItem?
  var rolloverObservers: [NSObjectProtocol] = []

  init() {
    rollOverIfNewWeek()
    observeDateChanges()
  }

  deinit {
    rolloverObservers.forEach { observer in
      NotificationCenter.default.removeObserver(observer)
      NSWorkspace.shared.notificationCenter.removeObserver(observer)
    }
  }

  func debouncedSave() {
    self.saveTask?.cancel()

    let task = DispatchWorkItem { [todos, weak self] in
      DispatchQueue.global(qos: .background).async { [weak self] in
        if let self {
          self.dataStore.saveTodos(todos: todos)
        }
      }
    }

    self.saveTask = task
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5, execute: task)
  }
}

// MARK: - Weekly Rollover

extension AppState {
  /// Archives last week's list and carries the unfinished todos into a new list
  /// once the current week (as set by the system's first weekday) has started.
  func rollOverIfNewWeek(now: Date = Date()) {
    guard let thisWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: now)?.start else {
      return
    }

    guard listWeekStart > 0 else {
      // First run with weekly lists: adopt the existing list as this week's
      // and save it so any dates added while loading are kept.
      listWeekStart = thisWeekStart.timeIntervalSince1970
      debouncedSave()
      return
    }

    let listWeek = Date(timeIntervalSince1970: listWeekStart)
    guard listWeek < thisWeekStart else {
      return
    }

    if !todos.isEmpty {
      let usedTagIDs = Set(todos.compactMap(\.tagID))
      let week = ArchivedWeek(
        weekStart: listWeek,
        todos: todos,
        tags: tags.filter { usedTagIDs.contains($0.id) }
      )
      guard dataStore.archive(week) else {
        // Keep the current list rather than lose it; try again at the next check.
        return
      }
    }

    listWeekStart = thisWeekStart.timeIntervalSince1970
    todos = todos.filter { !$0.isComplete }
  }

  func observeDateChanges() {
    let checkRollover: (Notification) -> Void = { [weak self] _ in
      self?.rollOverIfNewWeek()
    }

    rolloverObservers = [
      NotificationCenter.default.addObserver(
        forName: .NSCalendarDayChanged, object: nil, queue: .main, using: checkRollover
      ),
      NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didWakeNotification, object: nil, queue: .main, using: checkRollover
      )
    ]
  }
}

// MARK: - Computed Properties

extension AppState {
  var sortedTodosForMainMenu: [Todo] {
    let sorted = todos
    let sorter = todoSorting == .dateTime
    ? KeyPathComparator(\Todo.order)
    : KeyPathComparator(\Todo.title)

    switch completeHandling {
    case .strikeThrough:
      return sorted.sorted(using: sorter)
    case .sortToEnd:
      return sorted
        .sorted {
          $0.sortFactor(sortType: todoSorting) < $1.sortFactor(sortType: todoSorting)
        }
    case .hide, .delete, .moveToSubMenu:
      return sorted.filter { !$0.isComplete }.sorted(using: sorter)
    }
  }

  var sortedCompleteTodosForSubmenu: [Todo] {
    let completeTodos = todos.filter { $0.isComplete }

    let sorter = todoSorting == .dateTime
    ? KeyPathComparator(\Todo.order)
    : KeyPathComparator(\Todo.title)

    return completeTodos.sorted(using: sorter)
  }

  var sortedPendingTodosForSubMenu: [Todo] {
    let pendingTodos = todos.filter { !$0.isComplete }

    let sorter = todoSorting == .dateTime
    ? KeyPathComparator(\Todo.order)
    : KeyPathComparator(\Todo.title)

    return pendingTodos.sorted(using: sorter)
  }

  var allComplete: Bool {
    let totalTodos = todos.count
    let completedTodos = todos.count { $0.isComplete }
    return totalTodos == completedTodos
  }

  var allIncomplete: Bool {
    let completedTodos = todos.count { $0.isComplete }
    return completedTodos == 0
  }

  @ViewBuilder
  var todoButtons: some View {
    if completeHandling == .moveToSubMenu {
      todosPlusSubmenu
    } else {
      ForEach(sortedTodosForMainMenu) { todo in
        Button {
          self.toggleComplete(todo.id)
        } label: {
          self.menuLabel(for: todo) {
            Text(todo.wrappedTitle)
              .foregroundColor(todo.isComplete ? .secondary : .primary)
              .strikethrough(todo.isComplete ? true : false)
          }
        }
      }
    }
  }

  @ViewBuilder
  var todosPlusSubmenu: some View {
    let pendingTodos = sortedPendingTodosForSubMenu
    let completeTodos = sortedCompleteTodosForSubmenu

    if !pendingTodos.isEmpty {
      ForEach(pendingTodos) { todo in
        Button {
          self.toggleComplete(todo.id)
        } label: {
          self.menuLabel(for: todo) {
            Text(todo.wrappedTitle)
          }
        }
      }
    }

    Menu("Completed") {
      if completeTodos.isEmpty {
        Button {} label: {
          Text("No completed todos.")
        }
        .disabled(true)
      } else {
        ForEach(completeTodos) { todo in
          Button {
            self.toggleComplete(todo.id)
          } label: {
            self.menuLabel(for: todo) {
              Text(todo.wrappedTitle)
            }
          }
        }
      }
    }
  }

  func tag(for todo: Todo) -> Tag? {
    tags.first { $0.id == todo.tagID }
  }

  func menuLabel<Title: View>(for todo: Todo, @ViewBuilder title: () -> Title) -> some View {
    Label {
      title()
    } icon: {
      if let tag = tag(for: todo) {
        Image(nsImage: tag.color.menuImage)
          .renderingMode(.original)
          .accessibilityLabel(tag.name)
      }
    }
  }

  var menuTitle: some View {
    let title: LocalizedStringKey
    let accessTitle: LocalizedStringKey
    let imageName: String

    let totalTodos = todos.count
    let completedTodos = todos.filter { $0.isComplete }.count

    if totalTodos == 0 {
      title = "To-Day"
      imageName = "list.bullet.clipboard"
      accessTitle = ""
    } else if completedTodos == totalTodos {
      title = "To-Day: complete"
      imageName = "checklist.checked"
      accessTitle = "complete"
    } else if completeHandling == .delete {
      title = "To-Day: \(totalTodos) remaining"
      if completedTodos == 0 {
        imageName = "checklist.unchecked"
      } else {
        imageName = "checklist"
      }
      accessTitle = "\(totalTodos) remaining"
    } else {
      title = "To-Day: \(completedTodos) of \(totalTodos) done"
      if completedTodos == 0 {
        imageName = "checklist.unchecked"
      } else {
        imageName = "checklist"
      }
      accessTitle = "\(completedTodos) of \(totalTodos) done"
    }

    return HStack {
      Image(systemName: imageName)
      Text(title).monospacedDigit()
    }
    .accessibilityLabel(accessTitle)
  }
}

// MARK: - Methods

extension AppState {
  func createNewTodo(title: String) {
    let maxOrder = todos.reduce(0) { partialResult, todo in
      max(partialResult, todo.order)
    }
    let newTodo = Todo(order: maxOrder + 1, title: title)
    todos.append(newTodo)
  }

  func deleteTodo(_ todo: Todo) {
    todos.removeAll {
      $0.id == todo.id
    }
  }

  func deleteAllWithConfirmation() {
    let alert = NSAlert()
    alert.alertStyle = .warning
    alert.messageText = "Really delete all the todos?"
    alert.addButton(withTitle: "Delete")
    alert.addButton(withTitle: "Cancel")

    NSApp.activate(ignoringOtherApps: true)

    let response = alert.runModal()
    if response == .alertFirstButtonReturn {
      todos = []
    }
  }

  func createTag(name: String, color: TagColor) {
    tags.append(Tag(name: name, color: color))
  }

  func deleteTag(_ tag: Tag) {
    for index in todos.indices where todos[index].tagID == tag.id {
      todos[index].tagID = nil
    }
    tags.removeAll { $0.id == tag.id }
  }

  func deleteAll() {
    todos = []
  }

  func toggleComplete(_ id: UUID) {
    let todoIndex = todos.firstIndex {
      $0.id == id
    }
    if let todoIndex {
      if completeHandling == .delete {
        todos.remove(at: todoIndex)
      } else {
        todos[todoIndex].isComplete.toggle()
      }
    }
  }

  func markAll(complete: Bool) {
    for index in 0 ..< todos.count {
      todos[index].isComplete = complete
    }
  }

  func checkForDeleteCompleted() {
    guard completeHandling == .delete else {
      return
    }
    todos.removeAll { $0.isComplete }
  }
}
