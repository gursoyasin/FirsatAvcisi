const prisma = require('../config/db');
const firebase = require('../config/firebase');

async function sendPushNotification(userEmail, title, message, data = {}) {
    console.log(`[PUSH] Querying devices for: ${userEmail}`);

    try {
        // 1. Get tokens for this user
        const devices = await prisma.device.findMany({
            where: { userEmail: userEmail }
        });

        const tokens = devices.map(d => d.token);

        if (tokens.length === 0) {
            console.log(`⚠️ No registered devices for ${userEmail}. Skipping push.`);
            return;
        }

        // 2. Prepare FCM payload
        const payload = {
            notification: {
                title: title,
                body: message
            },
            data: {
                ...data,
                click_action: "FLUTTER_NOTIFICATION_CLICK" // Standard for many frameworks, but we'll use it as a general identifier
            },
            tokens: tokens
        };

        // 3. Send via Firebase
        const response = await firebase.messaging().sendEachForMulticast(payload);
        console.log(`✅ Push Sent! Success: ${response.successCount}, Failure: ${response.failureCount}`);

        // Optional: Clean up invalid tokens
        if (response.failureCount > 0) {
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    const errorCode = resp.error.code;
                    if (errorCode === 'messaging/registration-token-not-registered' || errorCode === 'messaging/invalid-registration-token') {
                        console.log(`🗑️ Removing invalid token: ${tokens[idx]}`);
                        prisma.device.delete({ where: { token: tokens[idx] } }).catch(() => { });
                    }
                }
            });
        }
    } catch (error) {
        console.error("❌ FCM Push Error:", error);
    }
}

async function handlePriceDrop(product, oldPrice, newPrice) {
    const discount = oldPrice - newPrice;
    const percentage = Math.round((discount / oldPrice) * 100);

    // Filter out negligible drops (less than 1%)
    if (percentage <= 0) return;

    const message = `🔥 İndirim! ${product.title} fiyatı %${percentage} düştü! (${newPrice} TL)`;

    console.log(`🚨 ALERT: ${message}`);

    // 1. Log to DB
    await prisma.alertLog.create({
        data: {
            productId: product.id,
            message: message,
            type: 'PRICE_DROP'
        }
    });

    // 2. Send Push to User's devices
    await sendPushNotification(product.userEmail, "Fiyat Düştü! 📉", message, { productId: String(product.id) });
}

async function handleStockAlert(product, currentPrice) {
    const message = `📦 Stokta! ${product.title} tekrar satışta! (${currentPrice} TL)`;
    console.log(`🚨 ALERT: ${message}`);

    await prisma.alertLog.create({
        data: {
            productId: product.id,
            message: message,
            type: 'STOCK_ALERT'
        }
    });

    await sendPushNotification(product.userEmail, "Stok Alarmı ✅", message, { productId: String(product.id) });
}

async function handleTargetPriceAlert(product, currentPrice) {
    const message = `🎯 Hedef Fiyat! ${product.title} istediğin fiyata (${currentPrice} TL) düştü.`;
    console.log(`🚨 ALERT: ${message}`);

    await prisma.alertLog.create({
        data: {
            productId: product.id,
            message: message,
            type: 'TARGET_PRICE'
        }
    });

    await sendPushNotification(product.userEmail, "Hedef Fiyat Yakalandı 🎯", message, { productId: String(product.id) });
}

module.exports = {
    handlePriceDrop,
    handleStockAlert,
    handleTargetPriceAlert
};
