-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Product" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "url" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "imageUrl" TEXT,
    "currentPrice" REAL NOT NULL,
    "originalPrice" REAL,
    "currency" TEXT NOT NULL DEFAULT 'TRY',
    "source" TEXT NOT NULL,
    "targetPrice" REAL,
    "deviceToken" TEXT,
    "userEmail" TEXT NOT NULL DEFAULT 'anonymous',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "inStock" BOOLEAN NOT NULL DEFAULT true,
    "category" TEXT,
    "gender" TEXT,
    "lastPriceDropAt" DATETIME,
    "bestAlternativePrice" REAL,
    "bestAlternativeSource" TEXT,
    "discountPercentage" REAL,
    "lastNotifiedPrice" REAL,
    "isSystem" BOOLEAN NOT NULL DEFAULT false,
    "views" INTEGER NOT NULL DEFAULT 0,
    "sellers" TEXT,
    "variants" TEXT,
    "barcode" TEXT,
    "aiAnalysis" TEXT,
    "scanCount" INTEGER NOT NULL DEFAULT 0,
    "firstTrackedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE'
);
INSERT INTO "new_Product" ("aiAnalysis", "barcode", "bestAlternativePrice", "bestAlternativeSource", "category", "createdAt", "currency", "currentPrice", "deviceToken", "discountPercentage", "gender", "id", "imageUrl", "inStock", "isSystem", "lastNotifiedPrice", "lastPriceDropAt", "originalPrice", "sellers", "source", "targetPrice", "title", "updatedAt", "url", "userEmail", "variants", "views") SELECT "aiAnalysis", "barcode", "bestAlternativePrice", "bestAlternativeSource", "category", "createdAt", "currency", "currentPrice", "deviceToken", "discountPercentage", "gender", "id", "imageUrl", "inStock", "isSystem", "lastNotifiedPrice", "lastPriceDropAt", "originalPrice", "sellers", "source", "targetPrice", "title", "updatedAt", "url", "userEmail", "variants", "views" FROM "Product";
DROP TABLE "Product";
ALTER TABLE "new_Product" RENAME TO "Product";
CREATE UNIQUE INDEX "Product_barcode_key" ON "Product"("barcode");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
