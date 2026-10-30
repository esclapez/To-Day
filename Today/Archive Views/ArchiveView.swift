//
//  ArchiveView.swift
//  To-Day
//

import SwiftUI

struct ArchiveView: View {
  @EnvironmentObject var appState: AppState
  @State private var weeks: [ArchivedWeek] = []
  @State private var selectedWeek: ArchivedWeek.ID?

  var body: some View {
    NavigationSplitView {
      List(weeks, selection: $selectedWeek) { week in
        VStack(alignment: .leading, spacing: 2) {
          Text(week.weekStart, format: .dateTime.day().month().year())
          Text("\(week.completedCount) of \(week.todos.count) done")
            .font(.caption)
            .foregroundColor(.secondary)
            .monospacedDigit()
        }
      }
      .navigationSplitViewColumnWidth(min: 160, ideal: 180)
      .overlay {
        if weeks.isEmpty {
          Text("No archived weeks yet.")
            .foregroundColor(.secondary)
        }
      }
    } detail: {
      if let week = weeks.first(where: { $0.id == selectedWeek }) {
        ArchivedWeekView(week: week)
      } else {
        Text("Select a week")
          .foregroundColor(.secondary)
      }
    }
    .toolbar {
      Button {
        NSWorkspace.shared.open(appState.dataStore.archiveFolderURL)
      } label: {
        Label("Show in Finder", systemImage: "folder")
      }
      .help("Show in Finder")
      .disabled(weeks.isEmpty)
    }
    .frame(minWidth: 550, minHeight: 350)
    .onAppear(perform: loadWeeks)
    .onChange(of: appState.listWeekStart) { _ in
      loadWeeks()
    }
  }

  func loadWeeks() {
    weeks = appState.dataStore.loadArchive()
    if selectedWeek == nil || !weeks.contains(where: { $0.id == selectedWeek }) {
      selectedWeek = weeks.first?.id
    }
  }
}

struct ArchivedWeekView: View {
  let week: ArchivedWeek

  var body: some View {
    List {
      Section {
        ForEach(week.todos.sorted(using: KeyPathComparator(\Todo.order))) { todo in
          ArchivedTodoRow(todo: todo)
        }
      } header: {
        Text("\(week.weekStart, format: .dateTime.day().month().year()) – \(week.weekEnd, format: .dateTime.day().month().year())")
      }
    }
  }
}

struct ArchivedTodoRow: View {
  let todo: Todo

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Image(systemName: todo.isComplete ? "checkmark.circle.fill" : "circle")
        .foregroundColor(todo.isComplete ? .green : .secondary)
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: 2) {
        Text(todo.title)
          .strikethrough(todo.isComplete)

        Group {
          Text("Created \(todo.createdAt, format: .dateTime.weekday().day().month().hour().minute())")
          if let completedAt = todo.completedAt {
            Text("Completed \(completedAt, format: .dateTime.weekday().day().month().hour().minute())")
          }
        }
        .font(.caption)
        .foregroundColor(.secondary)
      }
    }
    .accessibilityElement(children: .combine)
  }
}

struct ArchiveView_Previews: PreviewProvider {
  static var previews: some View {
    ArchiveView()
      .environmentObject(AppState())
  }
}
