//
//  EnvironmentValues+Command.swift
//  SmallFFmpegLocal
//
//  Created by Jose Vigil on 02/02/2025.
//

import Foundation
import SwiftUI

private struct CommandKey: EnvironmentKey {
    static let defaultValue: String = "" // Default value for the command
}

extension EnvironmentValues {
    var command: String {
        get { self[CommandKey.self] }
        set { self[CommandKey.self] = newValue }
    }
}
