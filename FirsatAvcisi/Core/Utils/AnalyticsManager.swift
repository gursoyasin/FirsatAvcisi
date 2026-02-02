import Foundation
import FirebaseAnalytics

/// Merkezi Analytics Yöneticisi
/// Firebase Analytics eventlerini yönetir
class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Ürün İşlemleri
    
    /// Ürün eklendiğinde
    func logProductAdded(source: String, price: Double, hasDiscount: Bool) {
        Analytics.logEvent("product_added", parameters: [
            "source": source,
            "price": price,
            "has_discount": hasDiscount,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    /// Ürün silindiğinde
    func logProductRemoved(source: String, daysTracked: Int) {
        Analytics.logEvent("product_removed", parameters: [
            "source": source,
            "days_tracked": daysTracked
        ])
    }
    
    /// Fiyat düşüşü bildirimi gönderildiğinde
    func logPriceDropNotification(oldPrice: Double, newPrice: Double, discountPercent: Double) {
        Analytics.logEvent("price_drop_notification", parameters: [
            "old_price": oldPrice,
            "new_price": newPrice,
            "discount_percent": discountPercent
        ])
    }
    
    /// Hedef fiyat ayarlandığında
    func logTargetPriceSet(originalPrice: Double, targetPrice: Double) {
        let discountExpectation = ((originalPrice - targetPrice) / originalPrice) * 100
        Analytics.logEvent("target_price_set", parameters: [
            "original_price": originalPrice,
            "target_price": targetPrice,
            "discount_expectation": discountExpectation
        ])
    }
    
    // MARK: - Kullanıcı Davranışları
    
    /// Sekme değiştirildiğinde
    func logTabChanged(tabName: String) {
        Analytics.logEvent("tab_changed", parameters: [
            "tab_name": tabName
        ])
    }
    
    /// Arama yapıldığında
    func logSearch(query: String, resultsCount: Int) {
        Analytics.logEvent("search_performed", parameters: [
            "query": query.lowercased(),
            "results_count": resultsCount
        ])
    }
    
    /// Ekran görüntülendiğinde
    func logScreenView(screenName: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenName
        ])
    }
    
    // MARK: - Monetization (Para Kazanma)
    
    /// Reklam izlendiğinde
    func logAdWatched(adType: String, reward: String? = nil) {
        var parameters: [String: Any] = [
            "ad_type": adType
        ]
        if let reward = reward {
            parameters["reward"] = reward
        }
        Analytics.logEvent("ad_watched", parameters: parameters)
    }
    
    /// Paywall gösterildiğinde
    func logPaywallShown(trigger: String) {
        Analytics.logEvent("paywall_shown", parameters: [
            "trigger": trigger
        ])
    }
    
    /// Abonelik satın alındığında
    func logSubscriptionPurchased(plan: String, price: Double, trialUsed: Bool) {
        Analytics.logEvent("subscription_purchased", parameters: [
            "plan": plan,
            "price": price,
            "trial_used": trialUsed
        ])
    }
    
    /// Abonelik iptal edildiğinde
    func logSubscriptionCancelled(plan: String, daysActive: Int) {
        Analytics.logEvent("subscription_cancelled", parameters: [
            "plan": plan,
            "days_active": daysActive
        ])
    }
    
    // MARK: - Özellik Kullanımı
    
    /// Koleksiyon oluşturulduğunda
    func logCollectionCreated(name: String, isPublic: Bool) {
        Analytics.logEvent("collection_created", parameters: [
            "name": name,
            "is_public": isPublic
        ])
    }
    
    /// Ürün paylaşıldığında
    func logProductShared(source: String, shareMethod: String) {
        Analytics.logEvent(AnalyticsEventShare, parameters: [
            "content_type": "product",
            "source": source,
            "method": shareMethod
        ])
    }
    
    // MARK: - Hata Takibi
    
    /// Hata oluştuğunda
    func logError(errorType: String, errorMessage: String, screen: String) {
        Analytics.logEvent("app_error", parameters: [
            "error_type": errorType,
            "error_message": errorMessage,
            "screen": screen
        ])
    }
    
    // MARK: - Kullanıcı Özellikleri
    
    /// Kullanıcı özelliklerini ayarla
    func setUserProperty(value: String, forName: String) {
        Analytics.setUserProperty(value, forName: forName)
    }
    
    /// Premium kullanıcı durumunu ayarla
    func setUserPremiumStatus(isPremium: Bool) {
        Analytics.setUserProperty(isPremium ? "premium" : "free", forName: "user_type")
    }
}
