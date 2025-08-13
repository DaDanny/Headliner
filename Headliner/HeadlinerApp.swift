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
            let mgr = SystemExtensionRequestManager(logText: "")
            ContentView(systemExtensionRequestManager: mgr, propertyManager: CustomPropertyManager(), outputImageManager: OutputImageManager())
                .frame(minWidth: 1280, maxWidth: 1360, minHeight: 900, maxHeight: 940)
                .onAppear {
                    #if DEBUG
                    // DEV only: always ask to activate the bundled extension (no-op if same build)
                    mgr.activateLatest()
                    #endif
                }
        }
    }
}
