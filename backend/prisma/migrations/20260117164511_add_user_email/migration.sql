-- CreateTable
CREATE TABLE "AlertLog" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "productId" INTEGER NOT NULL,
    "sentAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "message" TEXT NOT NULL,
    "type" TEXT NOT NULL DEFAULT 'PRICE_DROP',
    CONSTRAINT "AlertLog_productId_fkey" FOREIGN KEY ("productId") REFERENCES "Product" ("id") ON DELETE CASCADE ON UPDATE CASCADE
);

-- CreateTable
CREATE TABLE "Collection" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "_CollectionToProduct" (
    "A" INTEGER NOT NULL,
    "B" INTEGER NOT NULL,
    CONSTRAINT "_CollectionToProduct_A_fkey" FOREIGN KEY ("A") REFERENCES "Collection" ("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "_CollectionToProduct_B_fkey" FOREIGN KEY ("B") REFERENCES "Product" ("id") ON DELETE CASCADE ON UPDATE CASCADE
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
    "currency" TEXT NOT NULL DEFAULT 'TRY',
    "source" TEXT NOT NULL,
    "targetPrice" REAL,
    "deviceToken" TEXT,
    "userEmail" TEXT NOT NULL DEFAULT 'anonymous',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" DATETIME NOT NULL,
    "inStock" BOOLEAN NOT NULL DEFAULT true,
    "discountPercentage" REAL
);
INSERT INTO "new_Product" ("createdAt", "currency", "currentPrice", "deviceToken", "id", "imageUrl", "source", "targetPrice", "title", "updatedAt", "url") SELECT "createdAt", "currency", "currentPrice", "deviceToken", "id", "imageUrl", "source", "targetPrice", "title", "updatedAt", "url" FROM "Product";
DROP TABLE "Product";
ALTER TABLE "new_Product" RENAME TO "Product";
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

-- CreateIndex
CREATE UNIQUE INDEX "_CollectionToProduct_AB_unique" ON "_CollectionToProduct"("A", "B");

-- CreateIndex
CREATE INDEX "_CollectionToProduct_B_index" ON "_CollectionToProduct"("B");
