//
//  JSONFile.swift
//  MDI1-109-CryptoTracker
//
//  Created by Christian Bonilla on 30/10/25.
//

import SwiftUI
import UniformTypeIdentifiers

public struct JSONFile: FileDocument {
    public static var readableContentTypes: [UTType] = [.json]
    public var data: Data
    
    public init(data: Data) { self.data = data }
    
    public init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}
