//
//  FirsatAvcisiApp.swift
//  FirsatAvcisi
//
//  Created by yacN on 17.01.2026.
//

import SwiftUI

@main
@MainActor
struct FirsatAvcisiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var deepLinkManager = DeepLinkManager()
    @StateObject var uiState = UIState()
    @StateObject var networkMonitor = NetworkMonitor.shared
    
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(authViewModel)
                .environmentObject(deepLinkManager)
                .environmentObject(uiState)
                .environmentObject(networkMonitor)
                .onOpenURL { url in
                    deepLinkManager.handle(url: url)
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active {
                        AdManager.shared.showAppOpenAdIfAvailable()
                        SubscriptionManager.shared.refreshStats() // Force VIP Check
                    }
                }
        }
    }
}

