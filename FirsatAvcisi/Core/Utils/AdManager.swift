import SwiftUI
import Combine
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

class AdManager: NSObject {
    static let shared = AdManager()
    
    // Real IDs
    let bannerId = "ca-app-pub-3940256099942544/2934735716" // Test
    let interstitialId = "ca-app-pub-5243980726141810/5232638542" // Real Interstitial
    let nativeAdId = "ca-app-pub-5243980726141810/1070032253" // Real Native
    let rewardedAdId = "ca-app-pub-5243980726141810/1913993023" // Real Rewarded
    let appOpenAdId = "ca-app-pub-5243980726141810/4404424992" // Real App Open
    
    #if canImport(GoogleMobileAds)
    private var interstitial: GADInterstitialAd?
    private var rewardedAd: GADRewardedAd?
    private var appOpenAd: GADAppOpenAd?
    private var loadTime: Date?
    #endif
    
    override init() {
        super.init()
        #if canImport(GoogleMobileAds)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        loadInterstitial()
        loadRewardedAd()
        loadAppOpenAd()
        #endif
    }
    
    // MARK: - App Open Ad
    func loadAppOpenAd() {
        #if canImport(GoogleMobileAds)
        let request = GADRequest()
        GADAppOpenAd.load(withAdUnitID: appOpenAdId, request: request, orientation: UIInterfaceOrientation.portrait) { ad, error in
            if let error = error {
                print("App Open Ad failed to load: \(error)")
                return
            }
            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
            self.loadTime = Date()
        }
        #endif
    }
    
    func showAppOpenAdIfAvailable() {
        guard !SubscriptionManager.shared.isPro else { return }
        
        #if canImport(GoogleMobileAds)
        if let ad = appOpenAd, let time = loadTime, Date().timeIntervalSince(time) < (4 * 3600) {
            if let root = getRootViewController() {
                ad.present(fromRootViewController: root)
            }
        } else {
            loadAppOpenAd()
        }
        #endif
    }
    
    // MARK: - Interstitial
    func loadInterstitial() {
        #if canImport(GoogleMobileAds)
        let request = GADRequest()
        GADInterstitialAd.load(withAdUnitID: interstitialId, request: request) { ad, error in
            if let error = error {
                print("Failed to load interstitial: \(error)")
                return
            }
            self.interstitial = ad
        }
        #endif
    }
    
    func showInterstitial() {
        guard !SubscriptionManager.shared.isPro else { return }
        
        #if canImport(GoogleMobileAds)
        if let ad = interstitial {
            if let root = getRootViewController() {
                ad.present(fromRootViewController: root)
                loadInterstitial()
            }
        } else {
            loadInterstitial()
        }
        #endif
    }
    
    // MARK: - Rewarded
    func loadRewardedAd() {
        #if canImport(GoogleMobileAds)
        let request = GADRequest()
        GADRewardedAd.load(withAdUnitID: rewardedAdId, request: request) { ad, error in
            if let error = error {
                print("Failed to load rewarded ad: \(error)")
                return
            }
            self.rewardedAd = ad
        }
        #endif
    }
    
    func showRewardedAd(onReward: @escaping () -> Void) {
        #if canImport(GoogleMobileAds)
        if let ad = rewardedAd {
            if let root = getRootViewController() {
                ad.present(fromRootViewController: root) {
                    onReward()
                }
                loadRewardedAd()
            }
        } else {
            loadRewardedAd()
        }
        #endif
    }
    
    func getRootViewController() -> UIViewController? {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
        return screen.windows.first?.rootViewController
    }
}

// MARK: - Delegate
#if canImport(GoogleMobileAds)
extension AdManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        if ad is GADAppOpenAd {
            loadAppOpenAd()
        }
    }
}
#endif

// MARK: - Banner View
struct BannerAdView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeUIView(context: Context) -> UIView {
        #if canImport(GoogleMobileAds)
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = AdManager.shared.bannerId
        banner.rootViewController = AdManager.shared.getRootViewController()
        banner.load(GADRequest())
        banner.delegate = context.coordinator
        return banner
        #else
        return UIView()
        #endif
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    class Coordinator: NSObject {}
}
