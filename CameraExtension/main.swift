//
//  main.swift
//  CameraExtension
//
//  Created by Danny Francken on 8/2/25.
//

import Foundation
import CoreMediaIO

let providerSource = CameraExtensionProviderSource(clientQueue: nil)
CMIOExtensionProvider.startService(provider: providerSource.provider)

CFRunLoopRun()
