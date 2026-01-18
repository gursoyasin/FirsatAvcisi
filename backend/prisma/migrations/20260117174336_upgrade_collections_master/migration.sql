-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Collection" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "userEmail" TEXT NOT NULL DEFAULT 'anonymous',
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "isPublic" BOOLEAN NOT NULL DEFAULT false,
    "shareToken" TEXT,
    "type" TEXT NOT NULL DEFAULT 'MANUAL',
    "icon" TEXT NOT NULL DEFAULT 'folder',
    "query" TEXT
);
INSERT INTO "new_Collection" ("createdAt", "id", "name", "userEmail") SELECT "createdAt", "id", "name", "userEmail" FROM "Collection";
DROP TABLE "Collection";
ALTER TABLE "new_Collection" RENAME TO "Collection";
CREATE UNIQUE INDEX "Collection_shareToken_key" ON "Collection"("shareToken");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;
