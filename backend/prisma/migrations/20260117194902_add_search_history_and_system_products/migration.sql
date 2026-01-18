-- CreateTable
CREATE TABLE "SearchHistory" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "query" TEXT NOT NULL,
    "userEmail" TEXT NOT NULL DEFAULT 'anonymous',
    "searchedAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

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
    "lastPriceDropAt" DATETIME,
    "bestAlternativePrice" REAL,
    "bestAlternativeSource" TEXT,
    "discountPercentage" REAL,
    "isSystem" BOOLEAN NOT NULL DEFAULT false,
    "views" INTEGER NOT NULL DEFAULT 0
);
INSERT INTO "new_Product" ("bestAlternativePrice", "bestAlternativeSource", "category", "createdAt", "currency", "currentPrice", "deviceToken", "discountPercentage", "id", "imageUrl", "inStock", "lastPriceDropAt", "originalPrice", "source", "targetPrice", "title", "updatedAt", "url", "userEmail") SELECT "bestAlternativePrice", "bestAlternativeSource", "category", "createdAt", "currency", "currentPrice", "deviceToken", "discountPercentage", "id", "imageUrl", "inStock", "lastPriceDropAt", "originalPrice", "source", "targetPrice", "title", "updatedAt", "url", "userEmail" FROM "Product";
DROP TABLE "Product";
ALTER TABLE "new_Product" RENAME TO "Product";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
