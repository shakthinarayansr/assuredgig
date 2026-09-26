import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

/// The Partner's avatar and name in the app bar. One tap target, not two — a
/// small circle alone is too easy to miss with a thumb.
///
/// The avatar is the name's first letter for now. [WorkerProfile] carries a
/// photo *storage key*, not a URL, and resolving it needs a presigned-read
/// endpoint that does not exist yet; when it does, the image goes in
/// [_Avatar] with the initial as its placeholder and error fallback.
class PartnerHeader extends StatelessWidget {
  const PartnerHeader({required this.name, required this.onTap, super.key});

  /// Null before onboarding sets it, or when the profile could not be read.
  final String? name;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final palette = AppPalette.of(context);
    final label = name ?? l10n.headerNameFallback;

    return Semantics(
      button: true,
      label: l10n.headerOpenProfile,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppTheme.minTapTarget),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _Avatar(name: name),
                  const SizedBox(width: 10),
                  Flexible(
                    // The app bar's height is Material's, not ours, so a long
                    // name ellipsises here; the full name is still read out.
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String? name;

  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final initial = _initialOf(name);

    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.sky,
        shape: BoxShape.circle,
        border: Border.all(color: palette.divider),
      ),
      child: initial == null
          ? Icon(Icons.person, size: 22, color: palette.text)
          // Decorative: the name beside it is what gets read out.
          : ExcludeSemantics(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: palette.text,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
    );
  }

  /// First grapheme, not first code unit — a Tamil letter is often a consonant
  /// plus a vowel sign, and slicing between them draws half a letter.
  static String? _initialOf(String? name) {
    if (name == null || name.isEmpty) return null;
    return name.characters.first.toUpperCase();
  }
}
