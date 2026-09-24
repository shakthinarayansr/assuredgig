---
title: 57 analyzer errors that were one missing build_runner run
status: confirmed
date: 2026-09-09
found_by: fresh checkout of the login-ui-flow branch
tags: [tooling, codegen, onboarding]
links: []
---

## What we assumed

That a clean `flutter analyze` on a branch that was merged green would stay
clean after switching to it.

## What actually happened

57 errors, all of them plausible-looking: `copyWith` isn't defined for
`LoginState`, `LoginPhoneChanged` isn't a type, `getIt.init()` undefined.

The actual cause was two absent files — `lib/app/di.config.dart` and
`login_bloc.freezed.dart`. Generated code is not committed (CLAUDE.md §5), so a
fresh checkout has none of it. `dart run build_runner build` → zero issues.

## Why it was wrong

The errors point at the *consumers* of generated code, never at the generator.
Nothing in the output says "run the generator", so it reads like 57 real defects
in freshly written code.

## What changed

Nothing in the code. Worth knowing: `flutter pub get` runs `gen-l10n` through
build hooks, so `app_localizations.dart` *is* present — which makes the
diagnosis harder, because localisation works while freezed does not.

## How we'd catch it earlier

Before reading a large error list on a fresh checkout, check whether the
generated files exist:

```sh
ls lib/app/di.config.dart lib/**/*.freezed.dart 2>/dev/null || \
  dart run build_runner build
```

`dart run build_runner watch` avoids it entirely while iterating on blocs or
freezed models.
