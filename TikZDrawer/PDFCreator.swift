//  Created by Dominik Hauser on 05/05/2021.
//  
//

import Foundation

class PDFCreator {
  
  var token: NSObjectProtocol?
  @Published var standardOut: String = ""
  
  func create(from text: String, in url: URL) -> URL {
    
    let texString = """
      %!tikz editor 1.0
      \\documentclass{article}
      \\usepackage{tikz}
      \\usepackage{amsmath}
      \\begin{document}
      \\pagestyle{empty}
      \\begin{tikzpicture}
      \(text)
      \\end{tikzpicture}
      \\end{document}
      """
    
    let fileURL = url.appendingPathComponent("texFile.tex")
    try? texString.write(to: fileURL, atomically: true, encoding: .utf8)
    
    let stdOut = Pipe()
    let pdfTask = Process()
    pdfTask.currentDirectoryURL = url
    pdfTask.launchPath = "/Library/TeX/texbin/pdflatex"
    pdfTask.arguments = ["-halt-on-error", fileURL.path]
    pdfTask.environment = ["TEXMFOUTPUT": url.path, "TEXINPUTS": "\(url.path):"]
    pdfTask.standardOutput = stdOut
    
    token = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdOut.fileHandleForReading, queue: nil) { note in
      let handle = note.object as! FileHandle
      
      let string = String(data: handle.availableData, encoding: .utf8)
      if let string = string, false == string.isEmpty {
        self.standardOut.append(string)
      }
      
      handle.waitForDataInBackgroundAndNotify()
    }
    
    stdOut.fileHandleForReading.waitForDataInBackgroundAndNotify()
    
    pdfTask.launch()
    
    pdfTask.waitUntilExit()
    
    let pdfURL = url.appendingPathComponent("texFile.pdf")
    
    let cropTask = Process()
    cropTask.currentDirectoryURL = url
    cropTask.launchPath = "/Library/TeX/texbin/pdfcrop"
    cropTask.arguments = ["--gscmd", "/usr/local/bin/gs", "--pdftexcmd", "/Library/TeX/texbin/pdftex", pdfURL.path, pdfURL.path]
    cropTask.launch()
    
    cropTask.waitUntilExit()
    
    if let token = token {
      NotificationCenter.default.removeObserver(token)
    }
    return pdfURL
  }
}
