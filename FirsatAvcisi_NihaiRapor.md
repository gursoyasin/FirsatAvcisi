# 🦅 Fırsat Avcısı: Nihai Proje Raporu

**Tarih:** 20 Ocak 2026
**Durum:** Üretime Hazır (Production Ready)
**Sürüm:** 1.0.0

---

## 1. Uygulamanın Temel Amacı Nedir?

**Fırsat Avcısı**, moda tutkunlarının **Inditex Grubu** (Zara, Bershka, Pull&Bear, Stradivarius, Massimo Dutti, Oysho) başta olmak üzere online mağazalardaki ürünlerin **fiyat değişimlerini ve stok durumlarını** saniye saniye takip etmesini sağlayan akıllı bir alışveriş asistanıdır.

**Çözdüğü Sorun:**
Kullanıcılar beğendikleri bir indirimi beklerken sürekli sayfayı yenilemek zorunda kalırlar ve çoğu zaman indirimi kaçırırlar. Fırsat Avcısı, bu süreci %100 otonom hale getirir ve indirim olduğu saniye kullanıcıya haber verir.

---

## 2. Uygulama Neler Yapıyor? (Özellikler)

### A. Akıllı Fiyat Takibi
*   **Link ile Ekleme:** Kullanıcı, Zara veya Bershka uygulamasından kopyaladığı ürün linkini Fırsat Avcısı'na yapıştırır.
*   **Otomatik Analiz:** Uygulama, arka plandaki yapay zeka destekli botları (Cloud Miner) kullanarak ürünün resmini, ismini, fiyatını ve varyantlarını çeker.
*   **7/24 Nöbet:** Sistem, eklenen ürünleri belirli aralıklarla (Pro kullanıcılar için anlık, Ücretsiz kullanıcılar için günlük/saatlik) tarar.
*   **Anlık Bildirim:** Fiyat düştüğü anda telefonunuza bildirim gelir: *"Zara Ceket fiyatı 2.500 TL'den 1.800 TL'ye düştü! 📉"*

### B. Keşfet ve Vitrin (Dashboard)
*   **Trend Ürünler:** Diğer kullanıcıların en çok takip ettiği popüler ürünleri (Anonim olarak) ana sayfada listeler.
*   **Senin İçin Seçildi:** Kullanıcının geçmişte eklediği markalara göre kişiselleştirilmiş öneriler sunar.
*   **Canlı Fiyat Akışı:** Ana sayfadaki fiyatlar sürekli günceldir.

### C. Hedef Fiyat (Target Price) - *Pro Özellik*
*   Kullanıcı, *"Bu ürün 1.500 TL altına düşerse haber ver"* diyerek özel bir alarm kurabilir.

### D. İndirim Skorlaması
*   Her ürüne (geçmiş fiyat verisine dayanarak) 0-100 arası bir **"Fırsat Skoru"** verilir. (Örn: Skor 90 ise "Bu fiyata kaçmaz!", Skor 20 ise "Beklemek mantıklı").

---

## 3. Gelir Modeli (Para Kazanma Stratejisi)

Uygulama, "Hibrit Monetizasyon" (Çoklu Gelir) modeliyle çalışır.

### 1. Reklam Gelirleri (AdMob) - *Ücretsiz Kullanıcılar İçin*
*   **Açılış Reklamı (App Open):** Uygulamayı her açtıklarında çıkar.
*   **Vitrin Reklamı (Native):** Ana sayfada ürünlerin arasında doğal duran reklam kartları.
*   **Geçiş Reklamı (Interstitial):** Ürün ekleme gibi başarılı bir işlemden sonra çıkar.
*   **Ödüllü Reklam (Rewarded):** Ücretsiz ürün takip limiti (3 adet) dolduğunda, kullanıcıya *"Reklam izle, +1 hak kazan"* seçeneği sunulur.

### 2. Abonelik Gelirleri (Subscription) - *Sadık Kullanıcılar İçin*
*   **Fırsat Avcısı PRO (79.99 TL / Ay):**
    *   🛑 Reklamlar tamamen kalkar.
    *   ∞ Sınırsız ürün takip hakkı.
    *   ⚡️ Fiyat değişimlerinde öncelikli ve anlık bildirim (15 dk tarama sıklığı).
    *   🎯 Hedef fiyat belirleme özelliği açılır.

### 3. Satış Ortaklığı (Affiliate)
*   Kullanıcı "Satın Al" butonuna bastığında, uygulama arka planda linki değiştirir ve içine sizin "Referans Kodunuzu" ekler. (Amazon, Trendyol vb. destekler).

---

## 4. Teknik Altyapı (Nasıl Çalışıyor?)

Uygulama 3 ana bacaktan oluşur:

1.  **iOS Uygulaması (SwiftUI):**
    *   Kullanıcının gördüğü modern, Apple tasarım diline uygun arayüz.
    *   %100 Yerel (Native) performans.
    *   Deep Link entegrasyonu (Linke tıklayınca uygulamayı açma).

2.  **Bulut Madencisi (Cloud Miner / Node.js & Puppeteer):**
    *   Birisi link eklediğinde, sanal bir tarayıcı (Chrome) açıp siteye gider.
    *   Ürünün fotoğrafını, fiyatını ve stok bilgisini "kazır" (scrape).
    *   Inditex sitelerinin bot korumalarını (anti-bot) aşacak özel stratejiler kullanır.

3.  **Veritabanı ve Sunucu (Render & NeonDB):**
    *   **PostgreSQL:** Tüm kullanıcı, ürün ve fiyat geçmişi verilerini tutar.
    *   **API:** Uygulama ile veritabanı arasındaki güvenli köprüdür.

---

## 5. Sonuç

**Fırsat Avcısı**, sadece bir "istek listesi" uygulaması değildir; **aktif, canlı ve para kazandıran** bir ticaret platformudur. 

*   **Kullanıcı için:** İndirimleri kaçırmama garantisi sunar.
*   **Sizin için:** Reklam, abonelik ve komisyon üzerinden 3 farklı gelir kapısı olan tam otomatik bir iş modelidir.
