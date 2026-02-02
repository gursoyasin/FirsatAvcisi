import SwiftUI
import Combine
#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

struct NativeAdCard: View {
    @StateObject private var loader = NativeAdLoader()
    @State private var adLoaded = false
    
    var body: some View {
        if SubscriptionManager.shared.isPro {
            EmptyView()
        } else {
            VStack {
                if adLoaded {
                    NativeAdViewWrapper(nativeAd: loader.nativeAd)
                        .frame(height: 300) // Adjust height as needed
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                } else {
                    // Optional: Skeleton or empty
                    EmptyView()
                }
            }
            .onAppear {
                loader.loadAd()
            }
            .onReceive(loader.$nativeAd) { ad in
                if ad != nil { withAnimation { adLoaded = true } }
            }
        }
    }
}

class NativeAdLoader: NSObject, ObservableObject {
    @Published var nativeAd: Any? // Type erased for compilation without SDK
    
    #if canImport(GoogleMobileAds)
    private var adLoader: GADAdLoader!
    #endif
    
    func loadAd() {
        #if canImport(GoogleMobileAds)
        let multipleAdsOptions = GADMultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = 1
        
        adLoader = GADAdLoader(
            adUnitID: AdManager.shared.nativeAdId,
            rootViewController: AdManager.shared.getRootViewController(),
            adTypes: [.native],
            options: [multipleAdsOptions]
        )
        adLoader.delegate = self
        adLoader.load(GADRequest())
        #endif
    }
}

#if canImport(GoogleMobileAds)
extension NativeAdLoader: GADNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.nativeAd = nativeAd
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("Native ad failed: \(error)")
    }
}
#endif

// MARK: - UI Wrapper
struct NativeAdViewWrapper: UIViewRepresentable {
    let nativeAd: Any?
    
    func makeUIView(context: Context) -> UIView {
        #if canImport(GoogleMobileAds)
        guard let gadAd = nativeAd as? GADNativeAd else { return UIView() }
        
        // Create GADNativeAdView
        let nativeAdView = GADNativeAdView()
        
        // 1. Icon
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.clipsToBounds = true
        iconView.layer.cornerRadius = 8
        nativeAdView.addSubview(iconView)
        nativeAdView.iconView = iconView
        
        // 2. Headline
        let headlineLabel = UILabel()
        headlineLabel.font = .systemFont(ofSize: 17, weight: .bold)
        headlineLabel.numberOfLines = 1
        nativeAdView.addSubview(headlineLabel)
        nativeAdView.headlineView = headlineLabel
        
        // 3. Body
        let bodyLabel = UILabel()
        bodyLabel.font = .systemFont(ofSize: 14)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        nativeAdView.addSubview(bodyLabel)
        nativeAdView.bodyView = bodyLabel
        
        // 4. Media
        let mediaView = GADMediaView()
        mediaView.contentMode = .scaleAspectFit
        nativeAdView.addSubview(mediaView)
        nativeAdView.mediaView = mediaView
        
        // 5. Call to Action (Button)
        let ctaButton = UIButton()
        ctaButton.backgroundColor = .systemBlue
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.titleLabel?.font = .boldSystemFont(ofSize: 14)
        ctaButton.layer.cornerRadius = 18
        ctaButton.isUserInteractionEnabled = false // GADNativeAdView handles taps
        nativeAdView.addSubview(ctaButton)
        nativeAdView.callToActionView = ctaButton
        
        // 6. Ad Badge
        let badgeLabel = UILabel()
        badgeLabel.text = "REKLAM"
        badgeLabel.font = .systemFont(ofSize: 10, weight: .heavy)
        badgeLabel.textColor = .orange
        badgeLabel.layer.borderColor = UIColor.orange.cgColor
        badgeLabel.layer.borderWidth = 1
        badgeLabel.layer.cornerRadius = 3
        badgeLabel.textAlignment = .center
        nativeAdView.addSubview(badgeLabel)
        
        // --- LAYOUT ---
        [iconView, headlineLabel, bodyLabel, mediaView, ctaButton, badgeLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            // Header: Icon + Headline + Badge
            iconView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor, constant: 12),
            iconView.topAnchor.constraint(equalTo: nativeAdView.topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            headlineLabel.topAnchor.constraint(equalTo: iconView.topAnchor),
            headlineLabel.trailingAnchor.constraint(equalTo: badgeLabel.leadingAnchor, constant: -8),
            
            badgeLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            badgeLabel.topAnchor.constraint(equalTo: headlineLabel.topAnchor),
            badgeLabel.widthAnchor.constraint(equalToConstant: 44),
            badgeLabel.heightAnchor.constraint(equalToConstant: 16),
            
            bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
            bodyLabel.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            
            // Media
            mediaView.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            mediaView.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            mediaView.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 12),
            mediaView.heightAnchor.constraint(equalToConstant: 180),
            
            // CTA
            ctaButton.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor, constant: -12),
            ctaButton.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor, constant: -12),
            ctaButton.topAnchor.constraint(equalTo: mediaView.bottomAnchor, constant: 12),
            ctaButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            ctaButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        // Populate
        nativeAdView.nativeAd = gadAd
        (nativeAdView.headlineView as? UILabel)?.text = gadAd.headline
        (nativeAdView.bodyView as? UILabel)?.text = gadAd.body
        (nativeAdView.callToActionView as? UIButton)?.setTitle(gadAd.callToAction, for: .normal)
        (nativeAdView.iconView as? UIImageView)?.image = gadAd.icon?.image
        nativeAdView.mediaView?.mediaContent = gadAd.mediaContent
        
        return nativeAdView
        
        #else
        let view = UIView()
        let label = UILabel()
        label.text = "Native Ad Placeholder"
        label.textAlignment = .center
        label.frame = view.bounds
        label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(label)
        view.backgroundColor = .secondarySystemBackground
        return view
        #endif
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}
