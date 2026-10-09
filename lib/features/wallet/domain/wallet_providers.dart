import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_db.dart';
import '../../auth/data/supabase_providers.dart';
import '../../cards/domain/card_models.dart';
import 'wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(localDbProvider)),
);

/// Saved cards stream (offline-first). Falls back to empty when signed out.
final savedCardsProvider = StreamProvider<List<SavedCard>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(walletRepositoryProvider).watchSavedCards();
});

/// Write-side controller for the wallet (save scanned/received cards).
final walletControllerProvider =
    NotifierProvider<WalletController, AsyncValue<void>>(
  WalletController.new,
);

class WalletController extends Notifier<AsyncValue<void>> {
  static const _uuid = Uuid();

  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Saves a card snapshot directly into the local wallet (offline-first).
  Future<void> saveSnapshot(Card card, SavedCardSource source) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      throw StateError('Not signed in');
    }
    state = const Loading();
    try {
      await ref.read(walletRepositoryProvider).save(SavedCard(
            id: _uuid.v4(),
            ownerUserId: userId,
            cardId: card.id.isEmpty ? null : card.id,
            card: card,
            source: source,
            savedAt: DateTime.now(),
          ));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncFailure(e, st);
      rethrow;
    }
  }

  /// Saves a card received via short code. When [snapshotJson] is provided
  /// (offline QR scan), it is stored immediately without network. Otherwise
  /// Phase 3 fetches the public card from Supabase first.
  Future<void> saveFromShortCode(String shortCode, {String? snapshotJson}) async {
    Card? card;
    if (snapshotJson != null && snapshotJson.isNotEmpty) {
      try {
        card = Card.fromSnapshot(jsonDecode(snapshotJson) as Map<String, dynamic>);
      } catch (_) {
        card = null;
      }
    }
    // Placeholder keeps the wallet entry offline-usable until Phase 3 fetches
    // the full public card by short code.
    card ??= Card(
      id: '',
      userId: '',
      label: shortCode,
      fullName: shortCode,
      shortCode: shortCode,
    );
    await saveSnapshot(card, SavedCardSource.qrOnline);
  }
}
