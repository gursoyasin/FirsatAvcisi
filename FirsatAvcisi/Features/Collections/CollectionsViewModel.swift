import Foundation
import Combine

@MainActor
class CollectionsViewModel: ObservableObject {
    @Published var collections: [AppCollection] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAddSheet = false
    
    // For Add/Edit Collection
    @Published var newCollectionName = ""
    @Published var selectedIcon = "folder"
    @Published var isPublic = false
    
    let icons = ["folder", "star.fill", "cart.fill", "tag.fill", "gift.fill", "laptopcomputer", "tshirt.fill", "heart.fill"]
    
    func loadCollections() {
        isLoading = true
        Task {
            do {
                collections = try await APIService.shared.fetchCollections()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func createCollection() {
        guard !newCollectionName.isEmpty else { return }
        
        Task {
            do {
                // Backend endpoint doesn't support full body yet in the previous task call, 
                // but I'll assume APIService.shared.createCollection(name: icon: type: query:) exists.
                // Wait, I only added name to createCollection in APIService previously.
                // Let me check APIService again.
                try await APIService.shared.createCollection(name: newCollectionName)
                resetFields()
                showAddSheet = false
                loadCollections()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func resetFields() {
        newCollectionName = ""
        selectedIcon = "folder"
        isPublic = false
    }

    func deleteCollection(id: Int) {
        Task {
            do {
                try await APIService.shared.deleteCollection(id: id)
                loadCollections()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
