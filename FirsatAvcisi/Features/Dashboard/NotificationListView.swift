import SwiftUI
import Combine
import SwiftData

// MARK: - ViewModel
class NotificationViewModel: ObservableObject {
    @Published var isLoading = false
    // Alerts will now primarily come from SwiftData
    
    func fetchNotifications(modelContext: ModelContext) async {
        await MainActor.run { isLoading = true }
        do {
            let fetched = try await APIService.shared.fetchNotifications()
            await MainActor.run {
                // Sync Logic: Save fetched to SwiftData
                for alert in fetched {
                    // Check if exists
                    // For V1 simple logic: Just append or ignore duplicates
                    // In a real app we'd map AlertLog to SDNotification
                    
                    let newNotif = SDNotification(title: alert.title, body: alert.message, type: "price_drop", relatedProductId: alert.productId)
                    modelContext.insert(newNotif)
                }
                self.isLoading = false
            }
        } catch {
            print("Notification fetch error: \(error)")
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - View
struct NotificationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SDNotification.date, order: .reverse) private var notifications: [SDNotification]
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if notifications.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 20) {
                            Image(systemName: "bell.slash.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.secondary.opacity(0.3))
                                .padding(.top, 60)
                            Text("Henüz bir bildirim yok")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        ForEach(notifications) { notification in
                            HStack(alignment: .top, spacing: 16) {
                                // Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: notification.type == "price_drop" ? "arrow.down.circle.fill" : "bell.fill")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(notification.title)
                                        .font(.system(size: 15, weight: .bold)) // Bolder title
                                        .foregroundColor(.primary)
                                    
                                    Text(notification.body)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    Text(notification.date.formatted(.relative(presentation: .named)))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(16)
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                            .padding(.horizontal, 16)
                        }
                    }
                }
                .padding(.top, 10)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Bildirimler")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Kapat")
                    }
                }
            }
            .task {
                await viewModel.fetchNotifications(modelContext: modelContext)
            }
            .refreshable {
                await viewModel.fetchNotifications(modelContext: modelContext)
            }
        }
    }
}
