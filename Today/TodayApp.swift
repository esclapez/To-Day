//
//  TodayApp.swift
//  Today
//
//  Created by Sarah Reichelt on 16/1/2023.
//

import SwiftUI

@main
struct TodayApp: App {
  @StateObject var appState = AppState()

  var body: some Scene {
    MenuBarExtra {
      Group {
        appState.todoButtons

        EditGroup()

        SettingsGroup()

        AppGroup()
      }
      .environmentObject(appState)
    } label: {
      appState.menuTitle
    }

    Window("Edit Todos", id: "edit_todos") {
      EditView()
        .environmentObject(appState)
    }
    .defaultSize(width: 350, height: 400)

    Window("Past Weeks", id: "past_weeks") {
      ArchiveView()
        .environmentObject(appState)
    }
    .defaultSize(width: 650, height: 450)
  }
}
