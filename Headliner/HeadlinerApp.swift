//
//  HeadlinerApp.swift
//  Headliner
//
//  Created by Danny Francken on 8/2/25.
//

import SwiftUI

@main
struct HeadlinerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(systemExtensionRequestManager: SystemExtensionRequestManager(logText: ""))
                .frame(minWidth: 300, minHeight: 180)
        }
    }
}
