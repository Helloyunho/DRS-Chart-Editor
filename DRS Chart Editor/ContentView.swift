//
//  ContentView.swift
//  DRS Chart Editor
//
//  Created by Helloyunho on 2024/8/21.
//

import SwiftUI
import DRSKit
import DRSXMLImporter

class SmallModel: ObservableObject {
    @Published var seq = Seq(end: 120000, bpm: 12000)
}

struct ContentView: View {
    @State var navPath = NavigationPath()
    @State var showFileImporter = false
    @State var showError = false
    @State var fileImportError: Error? = nil
    @StateObject var smallModel = SmallModel()

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
                            let seq = try Seq.importXML(success)
                            smallModel.seq = seq
                            navPath.append(true)
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
                    let seq = Seq(end: 60000, bpm: 120)
                    smallModel.seq = seq
                    navPath.append(seq)
                } label: {
                    Text("Create new chart")
                }
            }
            .navigationDestination(for: Bool.self) { seq in
                ChartView(seq: $smallModel.seq)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button ("OK") {}
        } message: {
            Text(fileImportError?.localizedDescription ?? "Unknown error has occurred.")
        }
    }
}

#Preview {
    ContentView()
}
