//
//  Seq+FileDocument.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/9/1.
//
import DRSKit
import DRSXMLImporter
import XMLCoder
import Foundation
import UniformTypeIdentifiers
import SwiftUI

extension Seq: @retroactive FileDocument, @unchecked @retroactive Sendable {
    public static var readableContentTypes: [UTType] {
        [.xml]
    }
    
    public init(configuration: ReadConfiguration) throws {
        if let xmlData = configuration.file.regularFileContents {
            let seq = try Self.importXML(xmlData)
            self.init(info: seq.info, extends: seq.extends, rec: seq.rec, steps: seq.steps)
        } else {
            self.init(end: 0, bpm: 0)
        }
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: try self.exportXML())
    }
    
    
}
