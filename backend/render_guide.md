# Fırsat Avcısı: Render Deployment Guide

Tüm sistemin (Backend, Scraper, Database, iOS API) Render üzerinde Mac'teki gibi %100 performanslı çalışması için gereken adımlar ve kontrol listesi.

## 1. Hazırlık ve Gereksinimler

Kod tarafında gerekli tüm düzenlemeler yapıldı:
- **Browser/Puppeteer**: `.puppeteerrc.cjs` ile Render uyumlu hale getirildi.
- **Cache**: Chrome binary'si proje içine indirilecek şekilde ayarlandı.
- **Sağlık Kontrolü**: `/api/health/deep` rotası eklendi.

### Render Dashboard'da Yapılması Gerekenler
Render projenizin "Environment Variables" sekmesine gidip şunları eklediğinizden emin olun:

| Değişken Adı | Değer (Örnek) | Açıklama |
| :--- | :--- | :--- |
| `DATABASE_URL` | `postgres://user:pass@host/db?sslmode=require` | **KRİTİK**: Neon.tech veya Render Postgres URL'i. (SQLite Render'da çalışmaz!) |
| `NODE_ENV` | `production` | Performans optimizasyonu için. |
| `PUPPETEER_CACHE_DIR` | `/opt/render/project/src/backend/.cache/puppeteer` | Chrome'un kalıcı olması için (Build script bunu zaten ayarlıyor ama garanti olsun). |
| `SECRET_KEY` | `super-secret-key-...` | Güvenlik için. |

---

## 2. Sistem Kontrolü (Health Check)

Deploy işlemi bittikten sonra sistemin gerçekten çalışıp çalışmadığını anlamak için tarayıcıdan şu adrese gidin:

`https://<SİZİN-RENDER-URLNİZ>.onrender.com/api/health/deep`

### Beklenen Çıktı:
```json
{
  "checks": {
    "database": { "status": "ok", "type": "postgres" },
    "browser": { "status": "ok", "version": "Chrome/120..." },
    "filesystem": { "status": "ok" }
  }
}
```
Eğer `database` veya `browser` kısmında `"failed"` yazıyorsa, logları kontrol etmemiz gerekir.

---

## 3. Özellik Bazlı Kontrol Listesi

### ✅ Link Analiz (Backend)
- **Durum**: Hazır.
- **Test**: Uygulamadan "Ürün Ekle" diyerek bir Trendyol/Zara linki yapıştırın veya `/api/products/preview` endpointine POST atın.
- **Not**: İlk açılışta (Cold Start) yanıt vermesi 30-40 saniye sürebilir. Bu normaldir.

### ✅ Takip Listesi (Watchlist)
- **Durum**: Hazır.
- **Test**: Eklenen ürünlerin fiyatı değiştiğinde veritabanı güncellenir.
- **Otomasyon**: `scheduler.js` her 15 dakikada bir çalışarak fiyatları günceller. Render loglarında `⏰ [PRO] Watchlist Check Cycle...` yazısını görmelisiniz.

### ✅ Keşfet (Daily Miner)
- **Durum**: Hazır ancak RAM tüketimi yüksek.
- **Risk**: Ücretsiz Render paketinde (512MB RAM) aynı anda çok fazla site taranırsa "Out of Memory" hatası verebilir.
- **Çözüm**: Eğer çökme olursa, `scheduler.js` içindeki döngü süresini uzatabiliriz.

### ✅ Ayarlar (Settings)
- **Durum**: Hazır. `UserPreferences.swift` ve backend `/api/user` uyumlu.
- **Test**: Uygulamadan cinsiyet veya marka tercihlerini değiştirip uygulamayı kapatıp açın. Ayarlar korunuyorsa çalışıyordur.

---

## 4. Sorun Giderme (Troubleshooting)

**Sorun**: "Could not find Chrome" hatası alıyorum.
**Çözüm**: Backend klasöründeki `.puppeteerrc.cjs` dosyasının Render'a yüklendiğinden emin olun. Cache temizleyip tekrar deploy yapın ("Clear Build Cache & Deploy").

**Sorun**: Veritabanı bağlantı hatası.
**Çözüm**: `DATABASE_URL`'in doğru olduğunu ve sonuna `?sslmode=require` eklendiğini kontrol edin.

**Sorun**: Hiç ürün bulamıyor (0 products).
**Çözüm**: Hedef site (örn. Zara) Render IP'sini engelliyor olabilir. Bu durumda Proxy kullanmanız gerekebilir. Şu anki kodda Proxy desteği var ama `PROXY_LIST` env variable'ı boş.

---

Tüm bu adımlar tamamlandığında sisteminiz Mac'teki gibi sorunsuz çalışacaktır. Başarılar! 🚀
