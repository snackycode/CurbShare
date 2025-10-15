require('dotenv').config();
const functions = require('firebase-functions');
const admin = require('firebase-admin');
const express = require('express');
const bodyParser = require('body-parser');
const Stripe = require('stripe');
const { onSchedule } = require("firebase-functions/v2/scheduler");

admin.initializeApp();

// Environment variables
const STRIPE_SECRET_KEY = process.env.STRIPE_SECRET;
const STRIPE_WEBHOOK_SECRET = process.env.STRIPE_WEBHOOK_SECRET;
const APP_COMMISSION_PERCENT = Number(process.env.APP_COMMISSION_PERCENT) || 10;

// Validate keys
if (!STRIPE_SECRET_KEY) {
    console.error("⚠️ STRIPE_SECRET_KEY not found!");
    throw new Error("Stripe secret key is required");
}
if (!STRIPE_WEBHOOK_SECRET) {
    console.warn("⚠️ STRIPE_WEBHOOK_SECRET not found! Webhooks will fail.");
}

// Initialize Stripe
const stripe = Stripe(STRIPE_SECRET_KEY);

// Helper: cents <-> dollars
const toCents = (amount) => Math.round(amount * 100);

// ---------------- Stripe Functions ----------------

// Create a Stripe Express account for a host
// exports.createStripeAccount = functions.https.onCall(async (data, context) => {
//     console.log("Auth context:", context.auth);
//     if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in first.');

//     const uid = context.auth.uid;

//     try {
//         const account = await stripe.accounts.create({ type: 'express' });
//         await admin.firestore().collection('User').doc(uid).set({
//             stripeAccountId: account.id
//         }, { merge: true });

//         return { accountId: account.id };
//     } catch (err) {
//         console.error("createStripeAccount error:", err);
//         throw new functions.https.HttpsError('internal', err.message);
//     }
// });
exports.createStripeAccount = functions.https.onRequest(async (req, res) => {
    try {
        // Get Authorization header
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).send({ error: 'Unauthorized' });
        }

        const idToken = authHeader.split('Bearer ')[1];

        // Verify token manually
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const uid = decodedToken.uid;

        // Create Stripe account
        const account = await stripe.accounts.create({ type: 'express' });

        // Save to Firestore
        await admin.firestore().collection('User').doc(uid).set({
            stripeAccountId: account.id
        }, { merge: true });

        // Return response
        res.status(200).send({ accountId: account.id });
    } catch (err) {
        console.error("createStripeAccount error:", err);
        res.status(500).send({ error: err.message });
    }
});

// Node.js / Express
exports.createAccountLink = functions.https.onRequest(async (req, res) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).send({ error: 'Unauthorized' });
        }

        const idToken = authHeader.split('Bearer ')[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const uid = decodedToken.uid;

        const userDoc = await admin.firestore().collection('User').doc(uid).get();
        const stripeAccountId = userDoc.exists ? userDoc.data().stripeAccountId : null;
        if (!stripeAccountId) return res.status(400).send({ error: 'No Stripe account found' });

        const accountLink = await stripe.accountLinks.create({
            account: stripeAccountId,
            refresh_url: 'https://example.com/refresh',
            return_url: 'https://example.com/return',
            type: 'account_onboarding',
        });

        res.status(200).send({ url: accountLink.url });
    } catch (err) {
        console.error(err);
        res.status(500).send({ error: err.message });
    }
});

exports.topUpTestAccounts = functions.https.onRequest(async (req, res) => {
    try {
        const { role } = req.body; // expect JSON body { "role": "driver" or "host" }

        if (!role || (role !== 'driver' && role !== 'host')) {
            return res.status(400).json({ error: 'Invalid role' });
        }

        const amount = role === 'driver' ? 100000 : 10000; // in cents
        const destination = role === 'driver'
            ? 'acct_1SDQFN3iz3yx2gl6'
            : 'acct_1SDQ0w3iz3feVfLe';

        const paymentIntent = await stripe.paymentIntents.create({
            amount,
            currency: 'usd',
            automatic_payment_methods: {
                enabled: true,
                allow_redirects: 'never', // prevents redirect-based methods
            },
            transfer_data: { destination },
        });

        return res.json({ clientSecret: paymentIntent.client_secret });
    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: err.message });
    }
});

exports.verifyStripeAccount = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in first.');

    const accountId = data.accountId;
    try {
        const account = await stripe.accounts.retrieve(accountId);
        return {
            valid: account.type === 'express',
            chargesEnabled: account.charges_enabled,
            detailsSubmitted: account.details_submitted,
        };
    } catch (err) {
        throw new functions.https.HttpsError('not-found', 'Stripe account not found');
    }
});

// Create a Stripe customer
exports.createStripeCustomer = functions.https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in first.');
    const { name, email, phone } = data;
    if (!name || !email) throw new functions.https.HttpsError('invalid-argument', 'Name and email are required');

    try {
        const customer = await stripe.customers.create({ name, email, phone });
        await admin.firestore().collection('User').doc(context.auth.uid).set({
            stripeCustomerId: customer.id
        }, { merge: true });

        return { customerId: customer.id };
    } catch (err) {
        console.error("createStripeCustomer error:", err);
        throw new functions.https.HttpsError('internal', err.message);
    }
});

// Create a PaymentIntent and booking
// exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
//     if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in first.');
//     const uid = context.auth.uid;

//     const { lotId, hostId, start, end, bookingType, currency = 'usd' } = data;
//     if (!lotId || !hostId || !start || !end || !bookingType) {
//         throw new functions.https.HttpsError('invalid-argument', 'Missing parameters');
//     }

//     const startDt = new Date(start);
//     const endDt = new Date(end);

//     const lotSnap = await admin.firestore().collection('ParkingLot').doc(lotId).get();
//     const hostSnap = await admin.firestore().collection('User').doc(hostId).get();
//     if (!lotSnap.exists) throw new functions.https.HttpsError('not-found', 'Lot not found');
//     if (!hostSnap.exists) throw new functions.https.HttpsError('not-found', 'Host not found');

//     const lot = lotSnap.data();
//     const host = hostSnap.data();
//     const hostStripeAccount = host.stripeAccountId;
//     if (!hostStripeAccount) throw new functions.https.HttpsError('failed-precondition', 'Host has no Stripe account');

//     // Price calculation
//     const calculatePrice = (lot, bookingType, startDt, endDt) => {
//         if (bookingType === 'monthly') return lot.monthlyRate || 0;
//         if (bookingType === 'daily') return (lot.dailyRate || 0) * Math.max(1, Math.ceil((endDt - startDt) / (1000 * 60 * 60 * 24)));
//         return (lot.hourlyRate || 0) * Math.max(1, Math.ceil((endDt - startDt) / (1000 * 60 * 60)));
//     };

//     const amountFloat = calculatePrice(lot, bookingType, startDt, endDt);
//     const amountCents = toCents(amountFloat);
//     const appFeeCents = Math.round(amountCents * (APP_COMMISSION_PERCENT / 100));

//     const bookingRef = admin.firestore().collection('Booking').doc();
//     const bookingData = {
//         id: bookingRef.id,
//         lotId,
//         hostId,
//         driverId: uid,
//         start: admin.firestore.Timestamp.fromDate(startDt),
//         end: admin.firestore.Timestamp.fromDate(endDt),
//         bookingType,
//         amount: amountFloat,
//         amount_cents: amountCents,
//         appFeeCents,
//         status: 'pending',
//         createdAt: admin.firestore.FieldValue.serverTimestamp(),
//     };
//     await bookingRef.set(bookingData);

//     try {
//         const paymentIntent = await stripe.paymentIntents.create({
//             amount: amountCents,
//             currency,
//             payment_method_types: ['card'],
//             application_fee_amount: appFeeCents,
//             transfer_data: { destination: hostStripeAccount },
//             metadata: { bookingId: bookingRef.id, driverUid: uid, hostId, lotId },
//         });

//         await bookingRef.update({ paymentIntentId: paymentIntent.id, clientSecret: paymentIntent.client_secret ? true : false });

//         return { clientSecret: paymentIntent.client_secret, bookingId: bookingRef.id, amount: amountFloat, currency };
//     } catch (err) {
//         console.error("createPaymentIntent error:", err);
//         await bookingRef.delete();
//         throw new functions.https.HttpsError('internal', err.message);
//     }
// });


// exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
//   try {
//     const { lotId, hostId, start, end, bookingType, currency, amount } = req.body;

//     if (!amount || !hostId || !lotId) {
//       return res.status(400).json({ error: "Missing required parameters." });
//     }

//     // Host test account (for transfers)
//     const hostAccount = "acct_1SDQ0w3iz3feVfLe";

//     // Create a unique booking ID
//     const bookingId = `booking_${Date.now()}`;

//     // Create PaymentIntent
//     const paymentIntent = await stripe.paymentIntents.create({
//       amount: Math.floor(amount), // amount in cents
//       currency: currency || "usd",
//       automatic_payment_methods: {
//         enabled: true,
//         allow_redirects: "never",
//       },
//       transfer_data: { destination: hostAccount },
//       application_fee_amount: Math.floor(amount * 0.1), // 10% app fee
//       metadata: {
//         lotId,
//         hostId,
//         bookingType,
//         bookingId,
//       },
//     });

//     return res.json({
//       success: true,
//       clientSecret: paymentIntent.client_secret,
//       paymentIntentId: paymentIntent.id,
//       bookingId,
//     });
//   } catch (err) {
//     console.error("❌ Stripe error:", err);
//     return res.status(500).json({
//       success: false,
//       error: err.message || "Internal Server Error",
//     });
//   }
// });
// exports.createPaymentIntentThreeParty = functions.https.onRequest(async (req, res) => {
//     try {
//         const { lotId, driverId, hostId, start, end, bookingType, currency, amount } = req.body;

//         console.log("📌 Request body:", req.body);

//         if (!amount || !driverId || !hostId || !lotId) {
//             console.warn("⚠️ Missing required parameters");
//             return res.status(400).json({ error: "Missing required parameters." });
//         }

// const driverAccount = "acct_1SDQFN3iz3yx2gl6"; // driver connected account
// const hostAccount = "acct_1SDQ0w3iz3feVfLe";   // host connected account

//         // Convert dollars to cents and subtract 10% for host transfer
//         const totalAmount = Math.floor(amount);          // Payment amount in cents
//         const hostTransferAmount = Math.floor(amount * 0.9); // host receives 90%

//         console.log("💰 Total amount (cents):", totalAmount);
//         console.log("💳 Host transfer amount (cents):", hostTransferAmount);
//         console.log("👤 Driver account:", driverAccount);
//         console.log("🏠 Host account:", hostAccount);

//         // Create PaymentIntent on driver connected account
//         const paymentIntent = await stripe.paymentIntents.create({
//             amount: totalAmount,           // full payment from driver
//             currency: currency || "usd",
//             payment_method_types: ["card"],
//             on_behalf_of: driverAccount,   // driver pays
//             transfer_data: {
//                 destination: hostAccount,    // host receives net 90%
//                 amount: hostTransferAmount,  // amount host actually receives
//             },
//             metadata: {
//                 lotId,
//                 driverId,
//                 hostId,
//                 bookingType,
//             },
//         });

//         console.log("✅ PaymentIntent created:", paymentIntent.id);
//         console.log("🔑 Client secret:", paymentIntent.client_secret);

//         return res.json({
//             success: true,
//             clientSecret: paymentIntent.client_secret,
//             paymentIntentId: paymentIntent.id,
//         });

//     } catch (err) {
//         console.error("❌ Stripe error:", err);
//         return res.status(500).json({ success: false, error: err.message });
//     }
// });

exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
    try {
        const { lotId, driverId, hostId, amount, currency } = req.body;

        if (!driverId || !hostId || !amount) {
            return res.status(400).json({ error: "Missing required parameters" });
        }

        console.log("📌 Request body:", req.body);

        const totalAmount = Math.round(amount); // cents
        const platformFee = Math.floor(amount * 0.1); // 10% platform fee

        const hostStripeAccountId = "acct_1SDQ0w3iz3feVfLe"; // host test account

        // Create PaymentIntent with card
        const paymentIntent = await stripe.paymentIntents.create({
            amount: totalAmount,
            currency: currency || "usd",
            payment_method_types: ["card"],
            transfer_data: {
                destination: hostStripeAccountId, // Stripe calculates the rest
            },
            application_fee_amount: platformFee, // your platform fee
            description: `Demo card payment: Driver ${driverId} → Host ${hostId}`,
        });

        console.log("✅ PaymentIntent created:", paymentIntent.id);

        res.json({
            message: "Demo Stripe card payment succeeded",
            paymentIntentId: paymentIntent.id,
            clientSecret: paymentIntent.client_secret,
            totalAmount,
            platformFee,
        });

    } catch (err) {
        console.error("❌ Stripe demo error:", err);
        res.status(400).json({ error: err.message });
    }
});


// ---------------- Stripe Webhook ----------------
const app = express();

app.post('/stripeWebhook', bodyParser.raw({ type: 'application/json' }), async (req, res) => {
    const sig = req.headers['stripe-signature'];
    let event;
    try {
        event = stripe.webhooks.constructEvent(req.body, sig, STRIPE_WEBHOOK_SECRET);
    } catch (err) {
        console.error("Webhook signature verification failed:", err);
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    switch (event.type) {
        case 'payment_intent.succeeded': {
            const pi = event.data.object;
            const bookingId = pi.metadata?.bookingId;
            if (bookingId) {
                await admin.firestore().collection('Booking').doc(bookingId).update({
                    status: 'paid',
                    paymentIntentId: pi.id,
                    paidAt: admin.firestore.FieldValue.serverTimestamp(),
                    stripePaymentDetails: pi,
                });
            }
            break;
        }
        case 'payment_intent.payment_failed': {
            const pi = event.data.object;
            const bookingId = pi.metadata?.bookingId;
            if (bookingId) {
                await admin.firestore().collection('Booking').doc(bookingId).update({
                    status: 'failed',
                    paymentIntentId: pi.id,
                });
            }
            break;
        }
        default:
            console.log(`Unhandled event type: ${event.type}`);
    }

    res.json({ received: true });
});

exports.notifyBeforeBookingEnds = onSchedule(
    {
        schedule: "every 5 minutes",
        timeZone: "Asia/Phnom_Penh",
    },
    async (event) => {
        const db = admin.firestore();
        const now = new Date();

        const snapshot = await db
            .collection("Booking")
            .where("notifiedDriver", "==", false)
            .get();

        for (const doc of snapshot.docs) {
            const booking = doc.data();
            const endTime = booking.end.toDate();
            const notifyBefore = 10 * 60 * 1000; // 10 mins

            if (endTime - now <= notifyBefore && endTime - now > 0) {
                const driverDoc = await db.collection("User").doc(booking.driverId).get();
                const hostDoc = await db.collection("User").doc(booking.hostId).get();

                const driverToken = driverDoc.data()?.fcmToken;
                const hostToken = hostDoc.data()?.fcmToken;

                const message = {
                    notification: {
                        title: "Booking Ending Soon 🚗",
                        body: `Your booking ends at ${endTime.toLocaleTimeString()}`,
                    },
                };

                if (driverToken)
                    await admin.messaging().send({ ...message, token: driverToken });

                if (hostToken)
                    await admin.messaging().send({ ...message, token: hostToken });

                await doc.ref.update({ notifiedDriver: true, notifiedHost: true });
            }
        }

        return null;
    }
);


exports.stripeWebhook = functions.https.onRequest(app);

// ---------------- Test Connection ----------------
exports.testConnection = functions.https.onRequest(async (req, res) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).send({ message: 'Unauthorized' });
    }

    const idToken = authHeader.split('Bearer ')[1];
    try {
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        console.log('Decoded user:', decodedToken);
        res.send({ message: `Hello ${decodedToken.uid}` });
    } catch (err) {
        console.error('Token verification failed:', err);
        res.status(401).send({ message: 'Invalid token' });
    }
});

