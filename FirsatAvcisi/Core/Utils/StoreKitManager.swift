import Foundation
import StoreKit
import Combine

// MARK: - StoreKit Manager
@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()
    
    // ⚠️ DEĞİŞTİRİN: App Store Connect'teki ID ile birebir aynı olmalı
    let productIds = ["com.firsatavcisi.subscription.monthly"]
    
    @Published var products: [StoreKit.Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    
    // Transaction Listener Task
    var updateListenerTask: Task<Void, Error>? = nil
    
    init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Fetch products on launch
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // 1. Fetch Products
    func requestProducts() async {
        isLoading = true
        do {
            products = try await StoreKit.Product.products(for: productIds)
            print("StoreKit: \(products.count) products fetched.")
        } catch {
            print("StoreKit Error: Failed to fetch products: \(error)")
        }
        isLoading = false
    }
    
    // 2. Purchase
    func purchase(_ product: StoreKit.Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            // Check if transaction is verified
            let transaction = try checkVerified(verification)
            
            // Deliver content
            await updateCustomerProductStatus()
            
            // Finish transaction
            await transaction.finish()
            
        case .userCancelled:
            print("StoreKit: User cancelled")
        case .pending:
            print("StoreKit: Pending")
        @unknown default:
            break
        }
    }
    
    // 3. Listen for updates (Renewals, Revocations)
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    // Update status
                    await self.updateCustomerProductStatus()
                    // Finish
                    await transaction.finish()
                } catch {
                    print("StoreKit: Transaction failed verification")
                }
            }
        }
    }
    
    // 4. Update Status (Check Entitlements)
    func updateCustomerProductStatus() async {
        var purchased: Set<String> = []
        
        // Iterate current entitlements
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                // Check if not revoked
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            } catch {
                print("StoreKit: Failed verification")
            }
        }
        
        self.purchasedProductIDs = purchased
        
        // Update the main App Subscription Manager
        DispatchQueue.main.async {
            SubscriptionManager.shared.setStoreKitStatus(!purchased.isEmpty)
        }
    }
    
    // Helper: Verify JWS
    nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    enum StoreError: Error {
        case failedVerification
    }
}
