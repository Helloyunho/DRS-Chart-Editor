//
//  ContentView.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/21.
//

import SwiftUI
import DRSKit
import DRSXMLImporter

struct ContentView: View {
    @State var navPath = NavigationPath()
    @State var showFileImporter = false
    @State var showError = false
    @State var fileImportError: Error? = nil
    
    var body: some View {
        NavigationStack(path: $navPath) {
            VStack {
                Button {
                    showFileImporter.toggle()
                } label: {
                    Text("Import from file")
                }
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.xml]) { result in
                    switch result {
                    case .success(let success):
                        do {
                            guard success.startAccessingSecurityScopedResource() else { return }
                            navPath.append(try Seq.importXML(success))
                            success.stopAccessingSecurityScopedResource()
                        } catch {
                            fileImportError = error
                            showError = true
                        }
                    case .failure(let failure):
                        fileImportError = failure
                        showError = true
                    }
                }
                Divider()
                    .frame(maxWidth: 240)
                Button {
                    navPath.append(Seq(end: 60000, bpm: 120))
                } label: {
                    Text("Create new chart")
                }
            }
            .navigationDestination(for: Seq.self) { seq in
                ChartView(seq: seq)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button ("OK") {}
        } message: {
            Text(fileImportError?.localizedDescription ?? "Unknown Error")
        }
    }
}

#Preview {
    ContentView()
}
