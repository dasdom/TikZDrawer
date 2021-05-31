//  Created by Dominik Hauser on 04/05/2021.
//  
//

import SwiftUI

struct ContentView: View {
  
  @State var text: String = ""
  @State var filename: String = ""
  @State var pdfView: PDFKitView? = nil
  let creator = PDFCreator()
  @State private var dragOver = false
}

extension ContentView {
  var body: some View {
    GeometryReader { geometry in
      HStack {
        VStack {
          TextEditor(text: $text)
            .font(.system(size: 11, weight: .regular, design: .monospaced))
          
          ScrollView {
            HStack {
              Text(creator.standardOut)
                .multilineTextAlignment(.leading)
                .font(.system(size: 9, weight: .regular, design: .monospaced))
              
              Spacer()
            }
          }
          .frame(height: geometry.size.height/4)
          
          HStack {
            Button("Run", action: run)
              .keyboardShortcut(KeyEquivalent("r"), modifiers: .command)
            
            Spacer(minLength: 40)
            
            TextField("Filename", text: $filename)
            
            Button("Export", action: export)
          }
        }
        .frame(width: geometry.size.width/2)
        
        pdfView
          
      }
      .padding()
    }
    .onDrop(of: [(kUTTypeFileURL as String)], delegate: self)
    .onAppear(perform: load)
  }
  
  private func load() {
    let texFileURL = url().appendingPathComponent("texFile.tex")
    load(texFileURL: texFileURL)
  }
  
  private func load(texFileURL: URL) {
    
    do {
      let string = try String(contentsOf: texFileURL)
      var range = string.range(of: "\\begin{tikzpicture}\n")
      if let upperBound = range?.upperBound {
        range = string.range(of: "\n\\end{tikzpicture}")
        if let lowerBound = range?.lowerBound {
          let separated = string[upperBound..<lowerBound]
          print("separated: \(separated)")
          text = String(separated)
          run()
        }
      }
    } catch {
      print("error: \(error)")
    }
  }
  
  private func run() {
    
    self.pdfView = PDFKitView(url: nil)
    
    let pdfURL = creator.create(from: text, in: url())
    
    self.pdfView = PDFKitView(url: pdfURL)
  }
  
  func export() {
    
    guard false == filename.isEmpty else {
      return
    }
    
    let inputPDFURL = url().appendingPathComponent("texFile.pdf")
    let outputPDFURL = url().appendingPathComponent(filename + ".pdf")
    
    do {
      try FileManager.default.removeItem(at: outputPDFURL)
    } catch {
      print("error: \(error)")
    }
    
    do {
      try FileManager.default.copyItem(at: inputPDFURL, to: outputPDFURL)
    } catch {
      print("error: \(error)")
    }
    
    let inputTexURL = url().appendingPathComponent("texFile.tex")
    let outputTexURL = url().appendingPathComponent(filename + ".tex")
    
    do {
      try FileManager.default.removeItem(at: outputTexURL)
    } catch {
      print("error: \(error)")
    }
    
    do {
      try FileManager.default.copyItem(at: inputTexURL, to: outputTexURL)
    } catch {
      print("error: \(error)")
    }
  }
  
  func url() -> URL {
    let url: URL
    do {
      let applicationSupport = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
      let name = "TikZDrawer"
//      let name = Bundle.main.bundleIdentifier!
      let appSupportSubDirectory = applicationSupport.appendingPathComponent(name, isDirectory: true)
      try FileManager.default.createDirectory(at: appSupportSubDirectory, withIntermediateDirectories: true, attributes: nil)
      print(appSupportSubDirectory.path)
      url = appSupportSubDirectory
    } catch {
      fatalError()
    }
    return url
  }
}

extension ContentView: DropDelegate {
  func performDrop(info: DropInfo) -> Bool {
    guard let itemProvider = info.itemProviders(for: [(kUTTypeFileURL as String)]).first else { return false }
    
    itemProvider.loadItem(forTypeIdentifier: (kUTTypeFileURL as String), options: nil) {item, error in
      guard let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
      print("url \(url)")
      load(texFileURL: url)
      run()
    }
    return true
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
