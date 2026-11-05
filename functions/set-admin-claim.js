const admin = require('firebase-admin');

async function main() {
  const uid = process.argv[2];
  if (!uid) {
    throw new Error('Usage: node set-admin-claim.js <firebase-auth-uid>');
  }

  admin.initializeApp();
  const user = await admin.auth().getUser(uid);
  await admin.auth().setCustomUserClaims(uid, {
    ...user.customClaims,
    admin: true,
  });
  console.log(`Administrator claim set for ${uid}. Ask the user to sign in again.`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
