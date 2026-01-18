const admin = require('firebase-admin');

// We'll use environment variables for security. 
// The user should set FIREBASE_SERVICE_ACCOUNT_JSON in their .env
// or we can try to find a file if it exists.
try {
    const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_JSON
        ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON)
        : null;

    if (serviceAccount) {
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        console.log("Firebase Admin Initialized ✅");
    } else {
        console.warn("⚠️ Firebase Service Account JSON not found in process.env. Push notifications will be disabled.");
    }
} catch (error) {
    console.error("❌ Firebase Admin Initialization Error:", error);
}

module.exports = admin;
