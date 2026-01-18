import Foundation
import Combine

@MainActor
class CollectionDetailViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Management features
    @Published var searchText = ""
    @Published var isEditMode = false
    @Published var selectedProductIDs: Set<Int> = []
    @Published var collection: AppCollection?
    
    var filteredProducts: [Product] {
        if searchText.isEmpty {
            return products
        }
        return products.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    func loadDetails(id: Int) {
        isLoading = true
        Task {
            @MainActor in
            do {
                let detail = try await APIService.shared.fetchCollection(id: id)
                self.products = detail.products ?? []
                // This assumes fetchCollection returns a CollectionDetail or similar
                // Wait, I updated Collection model to include products: [Product]?
                // Let me check APIService.fetchCollection signature.
                isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func toggleSelection(for id: Int) {
        if selectedProductIDs.contains(id) {
            selectedProductIDs.remove(id)
        } else {
            selectedProductIDs.insert(id)
        }
    }
    
    func removeFromCollection(collectionId: Int) async {
        isLoading = true
        do {
            for pid in selectedProductIDs {
                try await APIService.shared.removeProductFromCollection(collectionId: collectionId, productId: pid)
            }
            selectedProductIDs.removeAll()
            isEditMode = false
            loadDetails(id: collectionId)
        } catch {
            errorMessage = "Koleksiyondan çıkarılamadı"
        }
        isLoading = false
    }
    
    func shareCollection() -> String? {
        guard let token = collection?.shareToken else { return nil }
        return "https://firsatavcisi.app/share/\(token)"
    }
}
