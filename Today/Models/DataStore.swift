//
//  DataStore.swift
//  Today
//
//  Created by Sarah Reichelt on 17/1/2023.
//

import Foundation

struct DataStore {
  let fileURL = URL.documentsDirectory.appending(component: "todos.json")
  let archiveFolderURL = URL.documentsDirectory.appending(component: "Archive", directoryHint: .isDirectory)

  var encoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    return encoder
  }

  var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }

  func saveTodos(todos: [Todo]) {
    do {
      let data = try encoder.encode(todos)
      try data.write(to: fileURL)
    } catch {
      print(error)
    }
  }

  func loadTodos() -> [Todo] {
    do {
      let data = try Data(contentsOf: fileURL)
      let todos = try decoder.decode([Todo].self, from: data)
        .sorted(using: KeyPathComparator(\.order))
      return todos
    } catch {
      print(error)
    }

    return Todo.sampleToDos
  }
}

// MARK: - Archive

extension DataStore {
  func archiveFileURL(for weekStart: Date) -> URL {
    let dayFormat = Date.ISO8601FormatStyle(timeZone: .current).year().month().day()
    let fileName = weekStart.formatted(dayFormat) + ".json"
    return archiveFolderURL.appending(component: fileName)
  }

  /// Saves a week's todos to the archive, merging with any existing file for that week.
  /// Returns false if the archive could not be written, so the caller can keep the current list.
  func archive(_ week: ArchivedWeek) -> Bool {
    let fileURL = archiveFileURL(for: week.weekStart)
    var todos = week.todos

    if let data = try? Data(contentsOf: fileURL),
       let existing = try? decoder.decode(ArchivedWeek.self, from: data) {
      let newIDs = Set(todos.map(\.id))
      todos = existing.todos.filter { !newIDs.contains($0.id) } + todos
    }

    do {
      try FileManager.default.createDirectory(at: archiveFolderURL, withIntermediateDirectories: true)
      let encoder = encoder
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = try encoder.encode(ArchivedWeek(weekStart: week.weekStart, todos: todos))
      try data.write(to: fileURL, options: .atomic)
      return true
    } catch {
      print(error)
      return false
    }
  }

  func loadArchive() -> [ArchivedWeek] {
    let fileURLs = (try? FileManager.default.contentsOfDirectory(
      at: archiveFolderURL,
      includingPropertiesForKeys: nil
    )) ?? []

    return fileURLs
      .filter { $0.pathExtension == "json" }
      .compactMap { url in
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(ArchivedWeek.self, from: data)
      }
      .sorted { $0.weekStart > $1.weekStart }
  }
}
