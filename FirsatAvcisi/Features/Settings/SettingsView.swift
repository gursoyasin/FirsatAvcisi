import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var prefs = UserPreferences.shared
    @StateObject private var subManager = SubscriptionManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var showPaywall = false
    
    let brands = ["Zara", "Bershka", "Pull&Bear", "Stradivarius", "Massimo Dutti", "Oysho"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 👑 1. PRO STATUS CENTER
                    ProStatusCard(action: { showPaywall = true })
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 24) {
                        notificationSection
                        trackingBehaviorSection
                        genderSelectionSection
                        brandPreferencesSection
                        serviceModeSection
                        trustSection
                        supportSection
                        signOutSection
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Hesap ve Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    // MARK: - Sections
    
    private var notificationSection: some View {
        // 🔔 2. BİLDİRİM AKLI
        VStack(alignment: .leading, spacing: 16) {
             HStack(spacing: 8) {
                 Image(systemName: "bell.badge")
                     .font(.system(size: 12, weight: .bold))
                     .foregroundColor(.secondary)
                 Text("BİLDİRİM AKLI")
                     .font(.system(size: 12, weight: .black))
                     .foregroundColor(.secondary)
                     .tracking(1)
             }
             
             VStack(spacing: 12) {
                 ForEach(NotificationProfile.allCases) { profile in
                     ProfileRow(
                         title: profile.rawValue,
                         icon: profile.icon,
                         isSelected: prefs.notificationProfile == profile,
                         isLocked: !subManager.isPro && profile != .nearDiscount
                     ) {
                         selectProfile(profile)
                     }
                 }
             }
             .padding(20)
             .background(Color(uiColor: .systemBackground))
             .cornerRadius(20)
             .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
        }
    }
    
    private func selectProfile(_ profile: NotificationProfile) {
        if !subManager.isPro && profile != .nearDiscount {
            HapticManager.shared.impact(style: .medium)
            showPaywall = true
        } else {
            HapticManager.shared.impact(style: .light)
            prefs.notificationProfile = profile
        }
    }
    
    private var trackingBehaviorSection: some View {
        // 🎯 3. TAKİP DAVRANIŞI
        SettingsSection(title: "TAKİP DAVRANIŞI", icon: "target") {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bir ürünü kaç gün takip edelim?")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(spacing: 8) {
                        ForEach([7, 14, 30], id: \.self) { day in
                            ActionButton(
                                title: "\(day) Gün",
                                isSelected: prefs.trackingDays == day,
                                isLocked: !subManager.isPro && day == 30
                            ) {
                                if !subManager.isPro && day == 30 {
                                    HapticManager.shared.impact(style: .medium)
                                    showPaywall = true
                                } else {
                                    prefs.trackingDays = day
                                }
                            }
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("İndirim olmazsa ne yapalım?")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(spacing: 8) {
                        ForEach(TrackingAction.allCases) { action in
                            ActionButton(
                                title: action.rawValue,
                                isSelected: prefs.onNoDiscountAction == action,
                                isLocked: !subManager.isPro && action != .remind
                            ) {
                                if !subManager.isPro && action != .remind {
                                    HapticManager.shared.impact(style: .medium)
                                    showPaywall = true
                                } else {
                                    prefs.onNoDiscountAction = action
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var genderSelectionSection: some View {
        SettingsSection(title: "CİNSİYET TERCİHİ", icon: "person.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Hangi ürünlere odaklanalım?")
                    .font(.system(size: 14, weight: .medium))
                
                Picker("Cinsiyet", selection: $prefs.gender) {
                    Text("Kadın").tag("female")
                    Text("Erkek").tag("male")
                }
                .pickerStyle(.segmented)
                .onChange(of: prefs.gender) { newValue in
                    Task {
                        try? await APIService.shared.updateUserProfile(gender: newValue)
                        HapticManager.shared.impact(style: .medium)
                    }
                }
            }
        }
    }
    
    private var brandPreferencesSection: some View {
        // 👗 4. TARZ & MARKA TERCİHLERİ
        SettingsSection(title: "TARZ & MARKA TERCİHLERİ", icon: "tshirt") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(brands, id: \.self) { brand in
                        BrandChip(
                            title: brand,
                            isSelected: prefs.interestedBrands.contains(brand)
                        ) {
                            prefs.toggleBrand(brand)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var serviceModeSection: some View {
        // 🧘 5. HİZMET MODU
        SettingsSection(title: "HİZMET MODU", icon: "leaf") {
            VStack(spacing: 12) {
                ForEach(ServiceMode.allCases) { mode in
                    ModeRow(
                        mode: mode,
                        isSelected: prefs.serviceMode == mode,
                        isLocked: !subManager.isPro && mode != .balanced
                    ) {
                        if !subManager.isPro && mode != .balanced {
                            HapticManager.shared.impact(style: .medium)
                            showPaywall = true
                        } else {
                            prefs.serviceMode = mode
                        }
                    }
                }
            }
        }
    }
    
    private var trustSection: some View {
        // 🔐 6. GÜVEN & ŞEFFAFLIK
        SettingsSection(title: "GÜVEN & ŞEFFAFLIK", icon: "lock.shield") {
            VStack(alignment: .leading, spacing: 12) {
                TrustNote(title: "Verilerim nasıl kullanılıyor?", text: "Seni izlemiyoruz, ürünleri izliyoruz. Verilerin sadece sana özel indirimleri bulmak için taranır.")
                TrustNote(title: "Fiyatlar gerçek mi?", text: "Evet, her 15 dakikada bir markaların mağazalarından canlı veri alıyoruz.")
            }
        }
    }
    
    private var supportSection: some View {
        // 💬 7. DESTEK = İNSAN
        SettingsSection(title: "YARDIM VE DESTEK", icon: "bubble.left.and.exclamationmark.bubble.right") {
            VStack(spacing: 12) {
                SupportLink(title: "Bir indirim mi kaçırdın?", icon: "envelope") {
                    openEmail(subject: "İndirim Kaçırdım")
                }
                SupportLink(title: "Bunu beklemeye değer mi?", icon: "sparkles") {
                    openEmail(subject: "Ürün Analiz Desteği")
                }
                SupportLink(title: "Yanlış bildirim mi geldi?", icon: "exclamationmark.triangle") {
                    openEmail(subject: "Hatalı Bildirim")
                }
            }
        }
    }
    
    private var signOutSection: some View {
        // Bottom Actions
        VStack(spacing: 16) {
            Button(role: .destructive) {
                authViewModel.signOut()
            } label: {
                Text("Çıkış Yap")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(16)
            }
            
            HStack(spacing: 12) {
                Link("Gizlilik Politikası", destination: URL(string: "https://firsatavcisi.app/privacy")!)
                Text("•")
                Link("Kullanım Şartları", destination: URL(string: "https://firsatavcisi.app/terms")!)
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            
            Text("Versiyon 1.0.0 (Build 1)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.top, 24)
        .padding(.bottom, 40)
    }
    
    private func openEmail(subject: String) {
        let mailUrl = URL(string: "mailto:destek@firsatavcisi.app?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!
        UIApplication.shared.open(mailUrl)
    }
}


// MARK: - Premium Sub-components

struct ProStatusCard: View {
    @ObservedObject var subManager = SubscriptionManager.shared
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            if !subManager.isPro { action() }
        }) {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: subManager.isPro ? "crown.fill" : "lock.fill")
                                .foregroundColor(subManager.isPro ? .yellow : .white)
                            Text(subManager.isPro ? "Fırsat Avcısı PRO" : "Ücretsiz Paket")
                                .font(.system(size: 20, weight: .black, design: .serif))
                        }
                        Text(subManager.isPro ? "İndirimleri herkesten önce öğren" : "Pro'ya geç, sınırları kaldır")
                            .font(.caption)
                            .opacity(0.8)
                    }
                    Spacer()
                    
                    Text(subManager.isPro ? "AKTİF" : "YÜKSELT")
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .cornerRadius(4)
                }
                
                HStack(spacing: 12) {
                    BadgeItem(icon: "lightning.fill", text: "Anında", isLocked: !subManager.isPro)
                    BadgeItem(icon: "target", text: "Hedef", isLocked: !subManager.isPro)
                    BadgeItem(icon: "sparkles", text: "Olasılık", isLocked: !subManager.isPro)
                    BadgeItem(icon: "clock.fill", text: "Öncelik", isLocked: !subManager.isPro)
                }
                
                Divider().background(.white.opacity(0.3))
                
                Text(subManager.isPro ? "Bu ay PRO kullanıcılar 1.240 TL tasarruf etti." : "Pro kullanıcılar %40 daha fazla indirim yakalıyor.")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .foregroundColor(.white)
            .background(
                subManager.isPro 
                ? LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [Color.gray, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(24)
            .shadow(color: subManager.isPro ? .blue.opacity(0.3) : .black.opacity(0.2), radius: 15, x: 0, y: 10)
        }
    }
}

struct BadgeItem: View {
    let icon: String
    let text: String
    var isLocked: Bool = false
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isLocked ? "lock.fill" : icon)
                .font(.system(size: 14))
                .opacity(isLocked ? 0.6 : 1)
            Text(text)
                .font(.system(size: 9, weight: .bold))
                .opacity(isLocked ? 0.6 : 1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.secondary)
                    .tracking(1)
            }
            
            content()
                .padding(20)
                .background(Color(uiColor: .systemBackground))
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
        }
    }
}

struct ProfileRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var isLocked: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .primary : (isLocked ? .secondary.opacity(0.5) : .secondary))
                
                Spacer()
                
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct ActionButton: View {
    let title: String
    let isSelected: Bool
    var isLocked: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isLocked { Image(systemName: "lock.fill").font(.caption2) }
                Text(title)
            }
            .font(.system(size: 12, weight: .bold))
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .foregroundColor(isSelected ? .white : (isLocked ? .secondary.opacity(0.5) : .primary))
            .opacity(isLocked && !isSelected ? 0.6 : 1)
            .cornerRadius(10)
        }
    }
}

struct BrandChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.clear)
                .foregroundColor(isSelected ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color(.separator), lineWidth: 1)
                )
                .cornerRadius(12)
        }
    }
}

struct ModeRow: View {
    let mode: ServiceMode
    let isSelected: Bool
    var isLocked: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if isLocked { Image(systemName: "lock.fill").font(.caption2) }
                    Text(mode.rawValue)
                        .font(.system(size: 15, weight: .bold))
                    Spacer()
                    if isSelected {
                        Circle().fill(.blue).frame(width: 8, height: 8)
                    }
                }
                Text(mode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.05) : Color.clear)
            .cornerRadius(12)
            .opacity(isLocked ? 0.6 : 1)
        }
        .foregroundColor(isLocked ? .secondary : .primary)
    }
}

struct TrustNote: View {
    let title: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

struct SupportLink: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .foregroundColor(.primary)
    }
}
