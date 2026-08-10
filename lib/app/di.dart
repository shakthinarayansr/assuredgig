import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../core/l10n/locale_controller.dart';
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
}
