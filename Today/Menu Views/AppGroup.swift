//
//  AppGroup.swift
//  To-Day
//
//  Created by Sarah Reichelt on 18/2/2023.
//

import SwiftUI

struct AppGroup: View {
  var body: some View {
    Group {
      Divider()
        .accessibilityHidden(true)

      Button("Quit To-Day") {
        NSApp.terminate(nil)
      }
    }
  }
}

struct AppGroup_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      AppGroup()
    }
  }
}
