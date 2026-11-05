# School Online Voting and Survey System

A mobile-first Flutter application for school elections, surveys, student records, notifications, and support. It targets Android, iOS, and web, and uses the light-blue/white visual direction from the supplied UI specification.

## Run in demo mode

```sh
flutter pub get
flutter run -d chrome
```

Demo sign-in:

- Student ID: `2024-1887`
- Password: `demo1234`

Demo ballots, survey responses, and reports are held only in app memory. They are labeled as sample data and are not official or permanently stored. A submitted demo ballot cannot be submitted a second time during the same app session.

## Firebase setup

Firebase is optional for trying the app, but it is required for real accounts and persistent data.

1. Create a Firebase project and register Android and iOS apps. Add a Web app to run in Chrome.
   The generated Android application ID is `com.example.school_online_voting`; replace it with the school's registered package ID before release.
2. Enable Email/Password in Firebase Authentication. School staff provision accounts; public registration is not included.
3. Give each student an authentication email alias in the form `{normalized-student-id}@students.school.invalid` (lowercase, excluding characters other than letters, digits, dot, underscore, and hyphen). Assign a password through the approved school provisioning process. The student's actual email is not used as the login identifier.
4. Create `students/{firebaseAuthUid}` documents with `studentId`, `fullName`, `email`, `course`, `yearLevel`, and `section`.
5. Install the Firebase CLI and Functions dependencies. Deploy the Firestore/Storage rules and callable functions:

   ```sh
   firebase login
   firebase use --add
   cd functions
   npm install
   cd ..
   firebase deploy --only firestore:rules,firestore:indexes,storage,functions
   ```

6. Configure the app with the Firebase values for the target platform. Use that platform's `appId`:

   ```sh
   flutter run -d chrome `
     --dart-define=FIREBASE_API_KEY=your-api-key `
     --dart-define=FIREBASE_APP_ID=your-web-app-id `
     --dart-define=FIREBASE_MESSAGING_SENDER_ID=your-sender-id `
     --dart-define=FIREBASE_PROJECT_ID=your-project-id `
     --dart-define=FIREBASE_STORAGE_BUCKET=your-storage-bucket
   ```

   For Android or iOS, replace the target and use that registered app's `FIREBASE_APP_ID`. For iOS, also pass `--dart-define=FIREBASE_IOS_BUNDLE_ID=your.bundle.id`. These Firebase client settings are not service-account credentials; never put service-account keys in the app.

7. Grant an administrator custom claim using a trusted machine with Firebase Admin SDK Application Default Credentials configured. Use the Firebase Auth UID, not the student's ID:

   ```sh
   cd functions
   node set-admin-claim.js FIREBASE_AUTH_UID
   ```

   Have the administrator sign out and back in after setting the claim.

Once connected, the student app reads active elections, surveys, the signed-in student's own voting/survey records, and notifications from Firestore. Elections and surveys are created in the Admin Console; add the eligible students' Firebase Auth UIDs when creating each activity. The Admin Console can publish notices/results and review support reports. Reports and optional screenshots are sent to Firestore and Firebase Storage.

## Security notes

- `submitBallot` and `submitSurvey` are callable Cloud Functions. They check authentication, eligibility, activity status and schedule, question/candidate choices, and duplicate submissions inside Firestore transactions. Duplicate ballot requests use a deterministic student/election document key.
- Results are hidden until an administrator publishes them. Firestore rules deny direct client writes to ballots, responses, elections, candidates, and student records.
- Admin actions check the Firebase Auth `admin` custom claim in Cloud Functions. A role value in a client-editable profile document is not sufficient.
- **The supplied “My Votes” feature makes ballots voter-identifiable.** This implementation therefore stores the student's UID beside their selected candidates and is not a secret-ballot system. Do not deploy it for elections that require ballot secrecy without redesigning storage and receipt/history behavior to separate eligibility tracking from anonymous ballot choices.
- Replace the sample support email/phone shown in Contact Support before deployment.
- Review rules, eligibility imports, retention, privacy, and election procedures with the school's security and election administrators before real use.

## Project layout

```text
lib/
  core/services/    Firebase-aware repository and in-memory demo fixtures
  core/theme/       Material 3 color and component theme
  models/           Student, election, vote, survey, and notification models
  screens/          Authentication, dashboard, election, survey, admin, and support pages
  app.dart          GoRouter navigation and authentication/role gates
  main.dart         Optional Firebase initialization and demo startup
functions/          Callable Cloud Functions and admin-claim helper
firestore.rules     Firestore access controls
storage.rules       Support/candidate image access controls
```

Run automated tests with:

```sh
flutter test
flutter analyze
```
