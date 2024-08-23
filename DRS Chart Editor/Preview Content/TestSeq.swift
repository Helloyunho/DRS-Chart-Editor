//
//  TestSeq.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/22.
//

import Foundation
import DRSKit
import DRSXMLImporter
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
private let testBundleData = NSDataAsset(name: "seq")?.data
nonisolated(unsafe) var testSeq = testBundleData != nil ? try! Seq.importXML(testBundleData!) : nil
