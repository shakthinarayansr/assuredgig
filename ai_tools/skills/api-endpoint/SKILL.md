---
name: api-endpoint
description: Add a backend endpoint to the AssuredGig app through its four layers — provider, mapper, repository, use case, DI — with the conventions that CI enforces. Use when wiring any new API call, or when asked for a "provider" for an endpoint.
---

# Adding an endpoint

The four-layer direction (CLAUDE.md §4) is enforced by
`tool/check_conventions.dart`, so this order is not a style preference — a call
built in a different order will not compile.

Probe the endpoint first: `ai_tools/skills/endpoint-probe`.

## The five files

**1. DTO + provider** — `lib/sources/api/<area>_api_provider.dart`

Mirrors the payload field for field, including fields nothing consumes yet.
Wire types stay wire types: `status` is a `String` here, never an enum. No
mapping, no domain imports.

```dart
@lazySingleton
class XApiProvider {
  const XApiProvider(this._dio);
  final Dio _dio;

  Future<XResponse> fetch() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        Paths.x,
        options: authenticated(),   // only if the endpoint needs a token
      );
      return XResponse.fromJson(response.data ?? const {});
    } on DioException catch (error) {
      throw error.asApiException;   // nothing above sources/ imports Dio
    }
  }
}
```

`fromJson` defends every field — `as String? ?? ''`, `is num ? .toInt() : 0`.
A null the app did not expect must not throw inside a parser.

**2. Entity** — `lib/domain/entities/`. Typed, enum-carrying, no JSON, no
Flutter. Nullable only where the server genuinely sends null.

**3. Use case** — `lib/domain/usecases/`. An `abstract interface class` with one
`call()`. This is what blocs depend on, and the reason swapping the hand-written
provider for a generated client later touches one file.

**4. Mapper** — `lib/data/mappers/`. Wire strings → domain enums. Every
`switch` ends in a `_ =>` case landing on the **conservative** value, and
unknown list entries are kept, not dropped. Share one mapper across endpoints
so two calls cannot disagree about what a status means.

**5. Repository** — `lib/data/repositories/`. `@Injectable(as: UseCase)`; maps
DTO → entity and `ApiException` → a domain failure. Cache-first reads belong
here when Drift lands.

## Error mapping

`ApiFailureKind` → a domain failure enum. Never a message: state carries codes,
the screen carries words (`ai_tools/memory/2026-09-08-state-carries-failure-codes-not-strings.md`).

Map only what you have observed. An unrecognised server `code` falls through to
`unknown` — a confident wrong sentence is worse than a vague right one.

## Wiring and verification

DI is generated. `@lazySingleton` on providers, `@Injectable(as:)` on
repositories, then:

```sh
dart run build_runner build     # a missing binding is a warning here, not an error — read it
flutter analyze --fatal-infos   # switch exhaustiveness catches unhandled enum cases
dart run tool/check_conventions.dart
```

Verify with a `_RecordingAdapter` (`HttpClientAdapter` returning a canned body)
for mapping and header assertions, and one live call against an error path for
the real thing. Assert the negative too: that no `Authorization` header goes to
an unauthenticated endpoint.

## Non-negotiables

- **Writes do not go here.** Every state-changing action is an outbox row
  (CLAUDE.md §2). Auth is the documented exception — there is no session to
  queue against.
- **No PII in logs.** Never log bodies; `requestId` is the only safe correlator.
- **Config is served, not compiled.** A radius, window, threshold or wage floor
  in a `static const` is a bug (NFR-08).
