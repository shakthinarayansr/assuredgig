import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// A signed-in session, as held on disk.
class StoredSession {
  const StoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.sessionId,
    required this.workerId,
  });

  final String accessToken;
  final String refreshToken;

  /// Absolute, so a clock read at use time answers "is this stale?" without
  /// having to remember when it was issued.
  final DateTime accessTokenExpiresAt;

  /// The server's `issuedId` — the handle for this device's session. A login
  /// on another handset supersedes it, and the app learns that from the server.
  final String sessionId;

  final String workerId;

  bool isExpiredAt(DateTime now) => !now.isBefore(accessTokenExpiresAt);
}

/// The only place tokens are written or read.
///
/// Keychain/Keystore only, never shared preferences (TRD §8, NFR-05). Nothing
/// above `data/` ever sees a token: the login flow returns a destination, not
/// a credential.
@lazySingleton
class TokenStore {
  const TokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'auth.access_token';
  static const String _refreshTokenKey = 'auth.refresh_token';
  static const String _expiresAtKey = 'auth.access_expires_at';
  static const String _sessionIdKey = 'auth.session_id';
  static const String _workerIdKey = 'auth.worker_id';

  Future<void> save(StoredSession session) async {
    await Future.wait(<Future<void>>[
      _storage.write(key: _accessTokenKey, value: session.accessToken),
      _storage.write(key: _refreshTokenKey, value: session.refreshToken),
      _storage.write(
        key: _expiresAtKey,
        value: session.accessTokenExpiresAt.toUtc().toIso8601String(),
      ),
      _storage.write(key: _sessionIdKey, value: session.sessionId),
      _storage.write(key: _workerIdKey, value: session.workerId),
    ]);
  }

  Future<StoredSession?> read() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (accessToken == null || refreshToken == null) return null;

    final expiresAtRaw = await _storage.read(key: _expiresAtKey);
    final expiresAt = expiresAtRaw == null
        ? null
        : DateTime.tryParse(expiresAtRaw);

    return StoredSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      // An unreadable expiry is treated as already expired: the refresh path
      // recovers, whereas assuming validity produces a 401 on a real request.
      accessTokenExpiresAt:
          expiresAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sessionId: await _storage.read(key: _sessionIdKey) ?? '',
      workerId: await _storage.read(key: _workerIdKey) ?? '',
    );
  }

  /// Signs out.
  ///
  /// Deliberately narrow: it deletes the five auth keys and nothing else.
  /// **Queued attendance must survive re-auth** (CLAUDE.md §6) — a wipe of all
  /// storage here would destroy the outbox, which is the one bug in this file
  /// that would cost a Partner a day's pay.
  Future<void> clear() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresAtKey),
      _storage.delete(key: _sessionIdKey),
      _storage.delete(key: _workerIdKey),
    ]);
  }
}
