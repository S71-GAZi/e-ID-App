import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/config/app_config.dart';
import '../../../core/utils/short_code.dart';
import '../../auth/data/supabase_providers.dart';
import '../domain/card_models.dart';

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

/// Cards owned by the current user. Realtime updates are handled in Phase 2;
/// for now a simple query stream keeps the list fresh on changes.
class CardRepository {
  CardRepository(this._ref);

  final Ref _ref;
  SupabaseClient get _client => _ref.watch(supabaseClientProvider);

  Stream<List<Card>> watchUserCards(String userId) {
    return _client
        .from('cards')
        .select('''
          *,
          card_links ( id, type, url, sort_order )
        ''')
        .eq('user_id', userId)
        .order('created_at')
        .withConverter(
          (rows, count) => rows.map(_rowToCard).toList(),
        );
  }

  Future<Card> fetchByShortCode(String shortCode) async {
    // Public read of visible fields only — enforced by RLS + a security
    // definer view/function on the backend (see supabase/migrations.sql).
    final row = await _client
        .from('public_cards')
        .select('*')
        .eq('short_code', shortCode)
        .maybeSingle();
    if (row == null) {
      throw const CardNotFoundException();
    }
    return _rowToCard(row);
  }

  Future<Card> createCard(Card draft) async {
    final row = await _client
        .from('cards')
        .insert(draft.toRow()..['short_code'] = ShortCode.generate())
        .select()
        .single();
    await _replaceLinks(row['id'] as String, draft.socialLinks);
    return _rowToCard(row);
  }

  Future<Card> updateCard(Card card) async {
    final payload = card.toRow()
      ..remove('id')
      ..remove('user_id')
      ..remove('short_code') // short code is immutable once issued
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final row = await _client
        .from('cards')
        .update(payload)
        .eq('id', card.id)
        .select()
        .single();
    await _replaceLinks(card.id, card.socialLinks);
    return _rowToCard(row);
  }

  Future<void> deleteCard(String cardId) =>
      _client.from('cards').delete().eq('id', cardId);

  Future<void> setActive(String cardId, bool isActive) => _client
      .from('cards')
      .update({'is_active': isActive}).eq('id', cardId);

  Future<void> uploadPhoto(String userId, String cardId, List<int> bytes) async {
    final path = 'photos/$userId/$card.jpg';
    await _client.storage
        .from('card-photos')
        .uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));
  }

  String publicPhotoUrl(String userId) =>
      _client.storage.from('card-photos').getPublicUrl('photos/$userId/card.jpg');

  Future<void> _replaceLinks(String cardId, List<SocialLink> links) async {
    await _client.from('card_links').delete().eq('card_id', cardId);
    if (links.isEmpty) return;
    await _client.from('card_links').insert([
      for (var i = 0; i < links.length; i++)
        {'card_id': cardId, 'type': links[i].type.name, 'url': links[i].url, 'sort_order': i},
    ]);
  }

  Card _rowToCard(Map<String, dynamic> row) {
    var card = Card.fromRow(row);
    if (card.photoUrl == null && card.userId.isNotEmpty) {
      // Fall back to conventional storage path if column is empty.
      card = card.copyWith(photoUrl: null);
    }
    return card;
  }
}

class CardNotFoundException implements Exception {
  const CardNotFoundException();
}

final cardRepositoryProvider = Provider<CardRepository>((ref) => CardRepository(ref));

final userCardsStreamProvider = StreamProvider.family<List<Card>, String>(
  (ref, userId) => ref.watch(cardRepositoryProvider).watchUserCards(userId),
);
