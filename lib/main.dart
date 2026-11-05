import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/services/app_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = _firebaseOptionsFromEnvironment();
  final firebaseConfigured = options != null;

  if (firebaseConfigured) {
    try {
      await Firebase.initializeApp(options: options);
    } catch (error) {
      runApp(_FirebaseStartupError(error: error));
      return;
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppRepository(firebaseConfigured: firebaseConfigured),
      child: const VotingApp(),
    ),
  );
}

class _FirebaseStartupError extends StatelessWidget {
  const _FirebaseStartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      backgroundColor: const Color(0xFFDCEAFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 52),
                    const SizedBox(height: 12),
                    const Text(
                      'Firebase could not start',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Check the Firebase dart-define values and platform app configuration, then restart the app.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SelectableText('$error'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

FirebaseOptions? _firebaseOptionsFromEnvironment() {
  const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const appId = String.fromEnvironment('FIREBASE_APP_ID');
  const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  if ([apiKey, appId, senderId, projectId].any((value) => value.isEmpty)) {
    return null;
  }
  return FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: senderId,
    projectId: projectId,
    authDomain: '$projectId.firebaseapp.com',
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
    iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
  );
}
