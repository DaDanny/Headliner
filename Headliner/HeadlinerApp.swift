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
            ContentView(systemExtensionRequestManager: SystemExtensionRequestManager(logText: ""), propertyManager: CustomPropertyManager(), outputImageManager: OutputImageManager())
                .frame(minWidth: 1280, maxWidth: 1360, minHeight: 900, maxHeight: 940)
        }
    }
}
