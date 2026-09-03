import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

/// A stable identifier for this installation.
///
/// It is what binds a session to a handset (TRD §8): the server keys the
/// session on it, so a login elsewhere supersedes this one instead of running
/// alongside it. The server requires at least 8 characters; a v4 UUID is 36.
///
/// **Generated, not collected.** No hardware identifier — no IMEI, no
/// `ANDROID_ID`, no advertising id. A random value per install is exactly as
/// useful for session binding, carries no PII, and keeps the Play data-safety
/// declaration honest (NFR-07).
///
/// It resets on reinstall, or if secure storage is cleared. That reads to the
/// server as a new device and supersedes the old session — correct, if
/// occasionally surprising.
@lazySingleton
class DeviceIdProvider {
  DeviceIdProvider(this._storage);

  final FlutterSecureStorage _storage;

  static const String _key = 'device.id';
  static const Uuid _uuid = Uuid();

  /// Cached so concurrent callers on first launch cannot race and mint two.
  Future<String>? _pending;

  Future<String> get() => _pending ??= _readOrCreate();

  Future<String> _readOrCreate() async {
    final existing = await _storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) return existing;

    final created = _uuid.v4();
    await _storage.write(key: _key, value: created);
    return created;
  }
}
