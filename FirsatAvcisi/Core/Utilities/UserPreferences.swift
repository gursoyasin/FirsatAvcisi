import SwiftUI
import Combine

enum NotificationProfile: String, CaseIterable, Identifiable {
    case bigSales = "Sadece Büyük İndirimler (%30+)"
    case nearDiscount = "İndirime Yaklaşınca"
    case targetPrice = "Hedef Fiyat Olunca"
    case silentNight = "Asla Gece (22:00-09:00)"
    
    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .bigSales: return "flame.fill"
        case .nearDiscount: return "eye.fill"
        case .targetPrice: return "target"
        case .silentNight: return "moon.zzz.fill"
        }
    }
}

enum TrackingAction: String, CaseIterable, Identifiable {
    case remind = "Hatırlat"
    case suggest = "Öner"
    case remove = "Sessizce Kaldır"
    
    var id: String { self.rawValue }
}

enum ServiceMode: String, CaseIterable, Identifiable {
    case silent = "Sessiz Mod"
    case balanced = "Dengeli"
    case aggressive = "İndirim Sezonu (Agresif)"
    
    var id: String { self.rawValue }
    var description: String {
        switch self {
        case .silent: return "Tatildeyim, bildirimleri azalt."
        case .balanced: return "Normal takip akışı."
        case .aggressive: return "Daha sık kontrol ve anlık uyarı."
        }
    }
}

class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    @AppStorage("is_pro_user") var isPro: Bool = false
    @AppStorage("notification_profile") var notificationProfile: NotificationProfile = .nearDiscount
    @AppStorage("tracking_days") var trackingDays: Int = 30
    @AppStorage("on_no_discount_action") var onNoDiscountAction: TrackingAction = .remind
    @AppStorage("service_mode") var serviceMode: ServiceMode = .balanced
    @AppStorage("user_gender") var gender: String = "female"
    
    @Published var interestedBrands: Set<String> = []
    
    private init() {
        // Load brands from UserDefaults manually since Set isn't directly supported by AppStorage without RawRepresentable
        if let brands = UserDefaults.standard.stringArray(forKey: "interested_brands") {
            self.interestedBrands = Set(brands)
        }
    }
    
    func toggleBrand(_ brand: String) {
        if interestedBrands.contains(brand) {
            interestedBrands.remove(brand)
        } else {
            interestedBrands.insert(brand)
        }
        UserDefaults.standard.set(Array(interestedBrands), forKey: "interested_brands")
        
        // Sync with backend
        Task {
            try? await APIService.shared.updateUserProfile(brands: Array(interestedBrands))
        }
    }
}
