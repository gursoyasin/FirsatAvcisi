import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

class ShareViewController: SLComposeServiceViewController {
    
    // BACKEND URL (Hardcoded for MVP - Must match APIService)
    private let backendURL = "http://192.168.1.17:3000/api/products"

    override func isContentValid() -> Bool {
        // Only allow if we can find a URL provided
        return true
    }

    override func didSelectPost() {
        // Inform user it's working
        // SLComposeServiceViewController handles UI, we just do logic
        
        guard let extensionContext = extensionContext else { return }
        
        // Find URL in attachments
        for item in extensionContext.inputItems as? [NSExtensionItem] ?? [] {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] (item, error) in
                        guard let self = self else { return }
                        
                        if let url = item as? URL {
                            self.sendToBackend(url: url)
                        } else if let urlString = item as? String, let url = URL(string: urlString) {
                             self.sendToBackend(url: url)
                        }
                    }
                    return // Found one, stop processing
                }
            }
        }
    }
    
    private func sendToBackend(url: URL) {
        guard let endpoint = URL(string: backendURL) else { return }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Retrieve User Email from Shared Defaults
        if let sharedDefaults = UserDefaults(suiteName: "group.yacN.FirsatAvcisi"),
           let email = sharedDefaults.string(forKey: "userEmail") {
            request.setValue(email, forHTTPHeaderField: "X-User-Email")
        }
        
        // Only sending URL, backend handles scraping now (auto-scrape logic)
        let body = ["url": url.absoluteString]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Share Error: \(error)")
                    self.extensionContext?.cancelRequest(withError: error)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    // Success!
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                } else {
                    // Failed
                    let backendError = NSError(domain: "Network", code: 400, userInfo: [NSLocalizedDescriptionKey: "Kaydedilemedi"])
                   self.extensionContext?.cancelRequest(withError: backendError)
                }
            }
            task.resume()
        } catch {
             self.extensionContext?.cancelRequest(withError: error)
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }
}
