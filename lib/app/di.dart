import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../core/l10n/locale_controller.dart';
import '../sources/api/api_client.dart';
import '../sources/secure/token_store.dart';
import 'di.config.dart';

final GetIt getIt = GetIt.instance;

/// Builds the object graph. Awaited in `main` before `runApp` because some
/// registrations (the restored locale) must be resolved before first render.
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() => getIt.init();

/// Registrations that need async construction or come from a package we do not
/// own, and so cannot carry an `@injectable` annotation themselves.
@module
abstract class AppModule {
  @preResolve
  @singleton
  Future<LocaleController> get localeController => LocaleController.restore();

  /// One Dio for the whole app — a second would mean a second connection pool
  /// and a second set of interceptors to drift out of sync.
  @singleton
  Dio dio(TokenStore tokens) => buildDio(tokens);

  /// Keystore-backed storage for tokens and the device id. The 10.x defaults
  /// are already AES-GCM with RSA-OAEP key wrapping and no biometric prompt,
  /// which is what we want — a Partner must not face a fingerprint check to
  /// open the app at a venue.
  @singleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();
}
