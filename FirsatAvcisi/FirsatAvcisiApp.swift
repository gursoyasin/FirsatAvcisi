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
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(authViewModel)
                .environmentObject(deepLinkManager)
                .onOpenURL { url in
                    deepLinkManager.handle(url: url)
                }
        }
    }
}

