import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crash reporting. TRD §3 names Sentry; we use Crashlytics instead — see
  // CLAUDE.md §3. The PII rule carries over unchanged and is not optional:
  // no phone numbers, names, coordinates or tokens may reach a crash report,
  // whether as a message, a custom key, or a breadcrumb (NFR-05, NFR-07).
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Awaited: the object graph includes the restored locale, and rendering
  // before it resolves would flash the wrong language (TRD §11).
  await configureDependencies();

  runApp(const AssuredGigApp());
}
