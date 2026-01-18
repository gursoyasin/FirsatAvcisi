import SwiftUI
import VisionKit

struct ScannerView: UIViewControllerRepresentable {
    var didFinishScanning: ((_ result: String) -> Void)
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: ScannerView
        
        init(parent: ScannerView) {
            self.parent = parent
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            switch item {
            case .barcode(let code):
                guard let stringValue = code.payloadStringValue else { return }
                parent.didFinishScanning(stringValue)
            default:
                break
            }
        }
        
        // Auto scan logic can be added here if we don't want tap-to-scan
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // For now, let's require tap, or auto-scan first item
        }
    }
}
