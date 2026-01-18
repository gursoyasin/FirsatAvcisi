import SwiftUI
import Combine

struct CollectionSelectionView: View {
    let productId: Int
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = CollectionsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.collections) { collection in
                    Button {
                        addToCollection(collectionId: collection.id)
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                            Text(collection.name)
                            Spacer()
                            Image(systemName: "plus.circle")
                        }
                    }
                }
            }
            .navigationTitle("Koleksiyona Ekle")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(isPresented: $viewModel.showAddSheet) {
                NavigationView {
                    Form {
                        TextField("Koleksiyon Adı", text: $viewModel.newCollectionName)
                    }
                    .navigationTitle("Yeni Koleksiyon")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("İptal") { viewModel.showAddSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Oluştur") {
                                viewModel.createCollection()
                            }
                            .disabled(viewModel.newCollectionName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.height(200)])
            }
            .onAppear {
                viewModel.loadCollections()
            }
        }
    }
    
    private func addToCollection(collectionId: Int) {
        Task {
            do {
                try await APIService.shared.addProductToCollection(collectionId: collectionId, productId: productId)
                dismiss()
            } catch {
                print("Error adding to collection: \(error)")
            }
        }
    }
}
