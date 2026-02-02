import SwiftUI
import Combine

class AlertManager: ObservableObject {
    static let shared = AlertManager()
    
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var alertTitle = "Uyarı"
    
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .info
    
    private init() {}
    
    func show(title: String = "Uyarı", message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showAlert = true
    }
    
    func toast(_ message: String, type: ToastType = .info) {
        self.toastMessage = message
        self.toastType = type
        withAnimation {
            self.showToast = true
        }
        
        // Auto hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                self.showToast = false
            }
        }
    }
}

enum ToastType {
    case info, success, error, warning
    
    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        }
    }
}
