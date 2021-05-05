//  Created by Dominik Hauser on 05/05/2021.
//  
//

import AppKit
import SwiftUI
import PDFKit

// https://stackoverflow.com/a/61480852/498796
struct PDFKitView: View {
  var url: URL?
  var body: some View {
    PDFKitRepresentedView(url)
  }
}

struct PDFKitRepresentedView: NSViewRepresentable {
  let url: URL?
  init(_ url: URL?) {
    self.url = url
  }
  
  func makeNSView(context: Context) -> some NSView {
    let pdfView = PDFView()
    if let url = url {
      pdfView.document = PDFDocument(url: url)
    }
    pdfView.autoScales = true
    return pdfView
  }
  
  func updateNSView(_ nsView: NSViewType, context: Context) {
    if let pdfView = nsView as? PDFView {
      if let url = url {
        pdfView.document = PDFDocument(url: url)
      }
      pdfView.autoScales = true
    }
  }
}
