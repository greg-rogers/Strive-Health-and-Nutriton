const admin = require('firebase-admin');
const fs = require('fs');

// Load service account
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const firestore = admin.firestore();

const DEFAULT_GOALS = {
  calorieGoal: 2500,
  waterGoal: 2000,
  sleepGoal: 8,
  carbGoal: 50,
  proteinGoal: 30,
  fatGoal: 20,
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
};

async function seedGoalsForAllUsers() {
  const usersSnapshot = await firestore.collection('users').get();

  for (const userDoc of usersSnapshot.docs) {
    const userId = userDoc.id;
    const goalsDocRef = firestore.collection('users').doc(userId).collection('goals').doc('main');

    const goalsDoc = await goalsDocRef.get();

    if (!goalsDoc.exists) {
      console.log(`🟡 Creating full goal doc for user: ${userId}`);
      await goalsDocRef.set(DEFAULT_GOALS);
      console.log(`✅ Created full goals for ${userId}`);
    } else {
      console.log(`🔁 Merging macro goals for existing user: ${userId}`);

      const data = goalsDoc.data() || {};
      const updates = {};

      if (!data.carbGoal) updates.carbGoal = 50;
      if (!data.proteinGoal) updates.proteinGoal = 30;
      if (!data.fatGoal) updates.fatGoal = 20;

      if (Object.keys(updates).length > 0) {
        await goalsDocRef.set(updates, { merge: true });
        console.log(`✅ Updated macro goals for ${userId}`);
      } else {
        console.log(`⚪️ No update needed for ${userId}`);
      }
    }
  }

  console.log('🎉 Finished seeding and merging goals.');
}

seedGoalsForAllUsers().catch((err) => {
  console.error('❌ Error seeding goals:', err);
});
