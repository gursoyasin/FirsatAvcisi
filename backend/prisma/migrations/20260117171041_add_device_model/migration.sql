-- CreateTable
CREATE TABLE "Device" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "userEmail" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "Device_token_key" ON "Device"("token");
