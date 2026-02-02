import Foundation
import SwiftData

class DataManager {
    static let shared = DataManager()
    
    let modelContainer: ModelContainer
    let modelContext: ModelContext
    
    private init() {
        do {
            modelContainer = try ModelContainer(for: ProductEntity.self)
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    // MARK: - Product Operations
    
    func saveProduct(_ product: Product) {
        let entity = ProductEntity.from(product)
        modelContext.insert(entity)
        try? modelContext.save()
    }
    
    func saveProducts(_ products: [Product]) {
        for product in products {
            let entity = ProductEntity.from(product)
            modelContext.insert(entity)
        }
        try? modelContext.save()
    }
    
    func fetchAllProducts() -> [Product] {
        let descriptor = FetchDescriptor<ProductEntity>(sortBy: [SortDescriptor(\.id)])
        guard let entities = try? modelContext.fetch(descriptor) else { return [] }
        return entities.map { $0.toProduct() }
    }
    
    func fetchProduct(byId id: Int) -> Product? {
        let predicate = #Predicate<ProductEntity> { $0.id == id }
        let descriptor = FetchDescriptor<ProductEntity>(predicate: predicate)
        guard let entity = try? modelContext.fetch(descriptor).first else { return nil }
        return entity.toProduct()
    }
    
    func deleteProduct(byId id: Int) {
        let predicate = #Predicate<ProductEntity> { $0.id == id }
        let descriptor = FetchDescriptor<ProductEntity>(predicate: predicate)
        guard let entity = try? modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try? modelContext.save()
    }
    
    func deleteAllProducts() {
        do {
            try modelContext.delete(model: ProductEntity.self)
            try modelContext.save()
        } catch {
            print("Failed to delete all products: \(error)")
        }
    }
    
    func updateProduct(_ product: Product) {
        // Delete old and insert new (simple approach)
        deleteProduct(byId: product.id)
        saveProduct(product)
    }
}
