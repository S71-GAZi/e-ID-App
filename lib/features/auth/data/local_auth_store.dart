import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/storage/local_db.dart';
import '../../cards/domain/card_models.dart';

/// Local account record (offline-first). The device is the source of truth;
/// when Supabase credentials are configured this account can later be linked
/// to / upgraded into a real cloud account (Phase 2 sync).
class LocalAccount {
  const LocalAccount({
    required this.id,
    required this.fullName,
    this.email = '',
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String email;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'created_at': createdAt?.toIso8601String(),
      };

  factory LocalAccount.fromJson(Map<String, dynamic> j) => LocalAccount(
        id: j['id'] as String,
        fullName: j['full_name'] as String? ?? '',
        email: j['email'] as String? ?? '',
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}

/// Persists the local account + onboarding flag in the `app_meta` key/value
/// table. No passwords are stored locally — cloud auth is handled by
/// Supabase; the local mode is an anonymous device identity.
class LocalAuthStore {
  LocalAuthStore(this._db);

  static const _accountKey = 'local_account';
  static const _onboardedKey = 'onboarded';

  final LocalDb _db;

  LocalAccount? readAccount() {
    final raw = _db.getMeta(_accountKey);
    if (raw == null) return null;
    try {
      return LocalAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<LocalAccount> createAccount({
    required String fullName,
    String email = '',
  }) async {
    final account = LocalAccount(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      createdAt: DateTime.now(),
    );
    await _db.setMeta(_accountKey, jsonEncode(account.toJson()));
    await _db.setMeta(_onboardedKey, 'true');
    return account;
  }

  Future<void> signOut() async {
    await _db.deleteMeta(_accountKey);
    await _db.deleteMeta(_onboardedKey);
  }

  bool get onboarded => _db.getMeta(_onboardedKey) == 'true';
}

final localAuthStoreProvider = Provider<LocalAuthStore>(
  (ref) => LocalAuthStore(ref.watch(localDbProvider)),
);

/// Effective user id: Supabase session when signed in to the cloud, otherwise
/// the local device account. Everything downstream (cards, wallet) keys off
/// this value, which keeps feature code identical in both modes.
final effectiveUserIdProvider = Provider<String?>((ref) {
  final cloudId = ref.watch(currentUserIdProvider);
  if (cloudId != null) return cloudId;
  return ref.watch(localAuthStoreProvider).readAccount()?.id;
});

/// Convenience for prefilled card data during onboarding.
extension LocalAccountCardX on LocalAccount {
  Card draftCard() => Card(
        id: 'draft-$id',
        userId: id,
        label: AppStrings.en.work,
        fullName: fullName,
      );
}
