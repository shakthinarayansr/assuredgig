import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/constants/brand.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';

/// S-01 — the first screen, before anything else (AUTH-01).
///
/// Dark, because it is a moment rather than a form: there is nothing to fill
/// in, so the sunlight argument for a near-white field does not apply here.
///
/// **Each language is written in its own script, always.** A Partner who reads
/// only Tamil cannot be asked to find "Tamil" spelled in Latin, and the app has
/// not yet been told which of the two they read — so both labels ignore the
/// current locale entirely. Everything else on the screen follows the locale.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({required this.onSelected, super.key});

  /// Called after the locale is set, so the caller owns where the flow goes
  /// next rather than this screen knowing about routes.
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final localeController = getIt<LocaleController>();
    final current = localeController.locale.languageCode;

    Future<void> choose(Locale locale) async {
      await localeController.setLocale(locale);
      onSelected();
    }

    return Scaffold(
      backgroundColor: AppTokens.darkGround,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 56, 26, 30),
          child: ConstrainedBox(
            // Fills the viewport so the wordmark can sit at the top and the
            // choices near the bottom, but scrolls rather than overflowing when
            // the text scale is turned up.
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  86,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppTokens.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      Brand.name,
                      style: TextStyle(
                        fontFamily: AppTokens.latinFamily,
                        fontSize: 16,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.16,
                        color: AppTokens.darkInk,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 56),
                Text(l10n.chooseLanguage, style: AppTokens.display),
                const SizedBox(height: 32),
                _LanguageChoice(
                  label: l10n.languageTamil,
                  script: _Script.tamil,
                  selected: current == 'ta',
                  onTap: () => choose(const Locale('ta')),
                ),
                const SizedBox(height: 12),
                _LanguageChoice(
                  label: l10n.languageEnglish,
                  script: _Script.latin,
                  selected: current == 'en',
                  onTap: () => choose(const Locale('en')),
                ),
                const SizedBox(height: 26),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: AppTokens.darkInkFaint,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        l10n.languageChangeableLater,
                        style: const TextStyle(
                          fontFamily: AppTokens.latinFamily,
                          fontSize: 13,
                          height: 1.55,
                          color: AppTokens.darkInkFaint,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Script { latin, tamil }

/// One language, as a filled card.
///
/// The chosen one is a white fill rather than a heavier border: fill survives a
/// scratched screen in direct sun, which is the condition this app is read in.
class _LanguageChoice extends StatelessWidget {
  const _LanguageChoice({
    required this.label,
    required this.script,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final _Script script;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : AppTokens.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLanguage),
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppTokens.darkHairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            // Minimum, never fixed — Tamil sits taller than Latin at the same
            // point size, and this is the screen where that is most visible.
            constraints: const BoxConstraints(minHeight: 54),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: script == _Script.tamil
                          ? AppTokens.tamilFamily
                          : AppTokens.latinFamily,
                      fontSize: 30,
                      // Tamil needs the taller line or its descenders clip.
                      height: script == _Script.tamil ? 1.4 : 1.2,
                      fontWeight: FontWeight.w600,
                      letterSpacing: script == _Script.tamil ? 0 : -0.6,
                      color: selected ? AppTokens.ink : AppTokens.darkInk,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected ? Icons.check_circle : Icons.arrow_outward,
                  size: 26,
                  color: AppTokens.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
