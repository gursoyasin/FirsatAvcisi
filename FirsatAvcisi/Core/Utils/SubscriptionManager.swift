import SwiftUI
import Combine

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    
    @AppStorage("isProUser") var isPro: Bool = false
    @AppStorage("freeSlotCount") var freeSlotCount: Int = 3
    
    @Published var currentProductCount: Int = 0
    
    // State Tracks
    @Published var isManualPro: Bool = false
    @Published var isStoreKitPro: Bool = false
    
    // Product Limit
    var canAddProduct: Bool {
        if isPro { return true }
        return currentProductCount < freeSlotCount
    }
    
    // Centralized Status Logic
    private func recalcStatus() {
        let newValue = isManualPro || isStoreKitPro
        if isPro != newValue {
            withAnimation {
                isPro = newValue
            }
            print("🔐 Pro Status Updated: \(isPro) (Manual: \(isManualPro), StoreKit: \(isStoreKitPro))")
        }
    }
    
    func setStoreKitStatus(_ isActive: Bool) {
        self.isStoreKitPro = isActive
        recalcStatus()
    }
    
    func refreshStats() {
        print("🔄 Refreshing Stats & VIP Status...")
        Task {
            do {
                // 1. Check Product Count
                let response = try await APIService.shared.fetchProducts(limit: 1)
                await MainActor.run {
                    self.currentProductCount = response.pagination.total
                }
                
                // 2. Check Manual VIP Status (Backend Bridge)
                print("📡 Calling API to check VIP status...")
                let status = try await APIService.shared.checkUserStatus()
                print("📡 VIP Status Response: \(status.isPremium) - Type: \(status.type)")
                
                await MainActor.run {
                    self.isManualPro = status.isPremium
                    self.recalcStatus()
                    
                    if status.isPremium {
                        print("👑 Manual VIP Recognized")
                    } else {
                        print("👤 User is NOT VIP")
                    }
                }
            } catch {
                print("❌ Stats/VIP refresh failed: \(error)")
            }
        }
    }
    
    func unlockPro() {
        // Fallback / Debug only
        self.isManualPro = true
        self.recalcStatus()
        HapticManager.shared.notification(type: .success)
    }
    
    func restorePurchases() {
        Task {
            await StoreKitManager.shared.updateCustomerProductStatus()
            HapticManager.shared.notification(type: .success)
        }
    }
    
    func addFreeSlot() {
        withAnimation {
            self.freeSlotCount += 1
        }
        HapticManager.shared.notification(type: .success)
    }
}
