import 'package:flutter/material.dart';

import '../../app/di.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_controller.dart';
import '../../l10n/app_localizations.dart';

/// S-21 — Profile home, carrying the two app-wide settings a Partner can
/// change at any time: appearance, and language (S-29, AUTH-03).
///
/// Language sits inline rather than one level deeper because there are two
/// choices; a screen to hold two rows is a tap nobody needs. Identity,
/// availability, trusted contact, support and account deletion join this list
/// as those screens are built.
///
/// Both switches rebuild in place — no restart, nothing lost.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final themeController = getIt<ThemeController>();
    final localeController = getIt<LocaleController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          themeController,
          localeController,
        ]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          children: <Widget>[
            _SectionHeading(
              title: l10n.profileAppearanceHeading,
              hint: l10n.profileAppearanceHint,
            ),
            _ChoiceGroup(
              children: <Widget>[
                for (final mode in ThemeController.options)
                  _ChoiceRow(
                    icon: switch (mode) {
                      ThemeMode.system => Icons.brightness_auto_outlined,
                      ThemeMode.light => Icons.light_mode_outlined,
                      ThemeMode.dark => Icons.dark_mode_outlined,
                    },
                    label: switch (mode) {
                      ThemeMode.system => l10n.themeSystem,
                      ThemeMode.light => l10n.themeLight,
                      ThemeMode.dark => l10n.themeDark,
                    },
                    selected: themeController.mode == mode,
                    onTap: () => themeController.setMode(mode),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            _SectionHeading(title: l10n.profileLanguageHeading),
            _ChoiceGroup(
              children: <Widget>[
                // Each language in its own script, whatever the current
                // locale — a Tamil reader stuck in English must still be able
                // to find the way back.
                for (final locale in LocaleController.supportedLocales)
                  _ChoiceRow(
                    icon: Icons.translate,
                    label: switch (locale.languageCode) {
                      'ta' => l10n.languageTamil,
                      _ => l10n.languageEnglish,
                    },
                    selected:
                        localeController.locale.languageCode ==
                        locale.languageCode,
                    onTap: () => localeController.setLocale(locale),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            header: true,
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hint != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// A hairline-bordered card of mutually exclusive rows.
class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) Divider(color: palette.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One option. The chosen one is a **fill plus a check**, not a heavier border
/// or a colour alone: fill survives a scratched screen in sunlight, and the
/// check carries the meaning for a Partner who cannot tell the fill apart.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? palette.sky : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            // Minimum, never fixed — Tamil wraps taller (NFR-04).
            constraints: const BoxConstraints(
              minHeight: AppTheme.minTapTarget + 8,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: <Widget>[
                  Icon(
                    icon,
                    size: 24,
                    color: selected ? palette.primary : palette.textMuted,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: palette.text,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 24,
                    color: selected ? palette.primary : palette.textDisabled,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
