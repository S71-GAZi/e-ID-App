import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/config/app_config.dart';
import '../../../core/storage/local_db.dart';
import '../../../core/utils/short_code.dart';
import '../../auth/data/supabase_providers.dart';
import '../domain/card_models.dart';
import 'card_sync_service.dart';

/// All auth operations for the app. UI depends only on this class.
class AuthRepository {
  AuthRepository(this._ref);

  final Ref _ref;

  SupabaseClient get _client => _ref.watch(supabaseClientProvider);

  bool get isConfigured => AppConfig.hasSupabase;

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _client.auth.resetPasswordForEmail(email, redirectTo: '${AppConfig.publicBaseUrl}/reset-password');

  /// Google Sign-In via Supabase OAuth (PKCE web flow).
  Future<void> signInWithGoogle() => _client.auth.signInWithOAuth(
        Provider.google,
        redirectTo: Uri.parse('${AppConfig.publicBaseUrl}/auth-callback'),
      );

  /// Apple Sign-In via Supabase OAuth.
  Future<void> signInWithApple() => _client.auth.signInWithOAuth(
        Provider.apple,
        redirectTo: Uri.parse('${AppConfig.publicBaseUrl}/auth-callback'),
      );
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref));

/// Cards owned by the current user. OFFLINE-FIRST: reads/writes go to the
/// local Drift database immediately; when a Supabase session exists, changes
/// are queued (dirty flag) and pushed by [CardSyncService].
class CardRepository {
  CardRepository(this._ref);

  final Ref _ref;
  LocalDb get _db => _ref.watch(localDbProvider);

  /// Cloud client, but only when configured AND signed in to the cloud.
  SupabaseClient? get _cloudClient {
    if (!AppConfig.hasSupabase) return null;
    if (_ref.watch(currentUserIdProvider) == null) return null;
    return _ref.watch(supabaseClientProvider);
  }

  Stream<List<Card>> watchUserCards(String userId) => _db.watchLocalCards(userId);

  Future<List<Card>> cardsOf(String userId) => _db.localCardsOf(userId);

  Future<Card> fetchByShortCode(String shortCode) async {
    final client = _cloudClient;
    if (client == null) throw const CardNotFoundException();
    // Public read of visible fields only — enforced by RLS + a security
    // definer view on the backend (see supabase/migrations.sql).
    final row = await client
        .from('public_cards')
        .select('*')
        .eq('short_code', shortCode)
        .maybeSingle();
    if (row == null) {
      throw const CardNotFoundException();
    }
    return Card.fromRow(row);
  }

  /// Creates (or updates) a card locally and issues an unguessable short
  /// code on first save. The online QR works even before sync because the
  /// code is minted on-device and reserved server-side at sync time.
  Future<Card> saveCard(Card draft) async {
    var card = draft;
    if (card.shortCode.isEmpty) {
      card = card.copyWith(shortCode: ShortCode.generate());
    }
    final now = DateTime.now();
    card = Card(
      id: card.id,
      userId: card.userId,
      label: card.label,
      fullName: card.fullName,
      title: card.title,
      company: card.company,
      phones: card.phones,
      emails: card.emails,
      website: card.website,
      address: card.address,
      bio: card.bio,
      photoUrl: card.photoUrl,
      themeColor: card.themeColor,
      template: card.template,
      visibility: card.visibility,
      shortCode: card.shortCode,
      isActive: card.isActive,
      socialLinks: card.socialLinks,
      createdAt: card.createdAt ?? now,
      updatedAt: now,
    );
    await _db.upsertLocalCard(card);
    // Fire-and-forget sync attempt; failures stay queued as `dirty`.
    _trySync();
    return card;
  }

  void _trySync() {
    // Best-effort: push pending changes when a cloud session exists.
    try {
      _ref.read(cardSyncServiceProvider).syncNow();
    } catch (_) {/* container not ready — queue survives */}
  }

  Future<Card> createCard(Card draft) => saveCard(draft);

  Future<Card> updateCard(Card card) => saveCard(card);

  Future<void> deleteCard(String cardId) async {
    await _db.markLocalCardDeleted(cardId);
    _trySync();
  }

  Future<void> setActive(String cardId, bool isActive) async {
    await _db.setLocalCardActive(cardId, isActive);
    _trySync();
  }

  Future<void> uploadPhoto(String userId, String cardId, List<int> bytes) async {
    final client = _cloudClient;
    if (client == null) return; // offline: photo stays local for now
    final path = 'photos/$userId/$card.jpg';
    await client.storage
        .from('card-photos')
        .uploadBinary(path, Uint8List.fromList(bytes),
            fileOptions: const FileOptions(contentType: 'image/jpeg'));
  }

  String? publicPhotoUrl(String userId) => _cloudClient?.storage
      .from('card-photos')
      .getPublicUrl('photos/$userId/card.jpg');
}

class CardNotFoundException implements Exception {
  const CardNotFoundException();
}

final cardRepositoryProvider = Provider<CardRepository>((ref) => CardRepository(ref));

final userCardsStreamProvider = StreamProvider.family<List<Card>, String>(
  (ref, userId) => ref.watch(cardRepositoryProvider).watchUserCards(userId),
);
