import SwiftUI
import Combine

struct CollectionDetailView: View {
    let collectionId: Int
    let collectionName: String
    @StateObject private var viewModel = CollectionDetailViewModel()
    @State private var showingMoveSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                // Search Bar
                if !viewModel.products.isEmpty {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Klasör içinde ara...", text: $viewModel.searchText)
                    }
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.top, 5)
                }

                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.products.isEmpty {
                    VStack {
                        Image(systemName: "cart.badge.minus")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text("Bu koleksiyonda ürün yok.")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.filteredProducts) { product in
                                CollectionProductItem(product: product, viewModel: viewModel)
                            }
                        }
                        .padding()
                        .padding(.bottom, 80)
                    }
                }
            }
            
            // Bottom Action Bar for Edit Mode
            if viewModel.isEditMode {
                HStack(spacing: 20) {
                    Button(action: {
                        Task { await viewModel.removeFromCollection(collectionId: collectionId) }
                    }) {
                        VStack {
                            Image(systemName: "folder.badge.minus")
                            Text("Çıkar").font(.caption2)
                        }
                    }
                    .foregroundColor(.red)
                    .disabled(viewModel.selectedProductIDs.isEmpty)
                    
                    Spacer()
                    
                    Text("\(viewModel.selectedProductIDs.count) seçildi")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: { showingMoveSheet = true }) {
                        VStack {
                            Image(systemName: "arrow.right.doc.on.clipboard")
                            Text("Taşı").font(.caption2)
                        }
                    }
                    .foregroundColor(.blue)
                    .disabled(viewModel.selectedProductIDs.isEmpty)
                }
                .padding()
                .background(Material.thinMaterial)
                .cornerRadius(15)
                .padding()
                .transition(.move(edge: .bottom))
            }
        }
        .navigationTitle(collectionName)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        if let urlStr = viewModel.shareCollection(), let url = URL(string: urlStr) {
                             let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                             UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                        }
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button(viewModel.isEditMode ? "Bitti" : "Düzenle") {
                        viewModel.isEditMode.toggle()
                        if !viewModel.isEditMode { viewModel.selectedProductIDs.removeAll() }
                    }
                }
            }
        }
        .sheet(isPresented: $showingMoveSheet) {
            MoveToCollectionSheet(viewModel: viewModel, sourceId: collectionId)
        }
        .onAppear {
            viewModel.loadDetails(id: collectionId)
        }
    }
}

struct CollectionProductItem: View {
    let product: Product
    @ObservedObject var viewModel: CollectionDetailViewModel
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ProductGridCard(product: product)
            
            if viewModel.isEditMode {
                Color.white.opacity(0.1)
                    .onTapGesture { viewModel.toggleSelection(for: product.id) }
                
                Image(systemName: viewModel.selectedProductIDs.contains(product.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Circle().fill(Color.white))
                    .padding(4)
            } else {
                NavigationLink(destination: ProductDetailView(product: product)) {
                    Color.clear
                }
            }
        }
    }
}

struct MoveToCollectionSheet: View {
    @ObservedObject var viewModel: CollectionDetailViewModel
    let sourceId: Int
    @Environment(\.dismiss) var dismiss
    @StateObject var collectionsVM = CollectionsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                let otherCollections = collectionsVM.collections.filter { $0.id != sourceId }
                ForEach(otherCollections) { collection in
                    Button {
                        let pids = Array(viewModel.selectedProductIDs)
                        let targetId = collection.id
                        Task {
                            do {
                                try await APIService.shared.moveProducts(
                                    productIds: pids,
                                    from: sourceId,
                                    to: targetId
                                )
                                await MainActor.run {
                                    viewModel.isEditMode = false
                                    viewModel.selectedProductIDs.removeAll()
                                    viewModel.loadDetails(id: sourceId)
                                    dismiss()
                                }
                            } catch {
                                // Error handled by silence or add error state
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: collection.icon)
                            Text(collection.name)
                            Spacer()
                            Text("\(collection._count?.products ?? 0) ürün")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Nereye Taşıyalım?")
            .onAppear { collectionsVM.loadCollections() }
            .toolbar {
                 ToolbarItem(placement: .cancellationAction) {
                     Button("Kapat") { dismiss() }
                 }
            }
        }
    }
}
