import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/config/app_config.dart';
import '../../../core/storage/local_db.dart';
import '../../auth/data/supabase_providers.dart';
import '../domain/card_models.dart';

/// Pushes locally-queued card changes (dirty rows in `local_cards`) to
/// Supabase. Runs only when:
///   * Supabase credentials are configured, AND
///   * there is an active cloud session (signed in), AND
///   * at least one dirty row exists.
///
/// Everything stays functional without it — this is a background "catch-up"
/// pass, never a blocking operation for the UI.
class CardSyncService {
  CardSyncService(this._ref);

  final Ref _ref;

  bool get canSync =>
      AppConfig.hasSupabase && _ref.read(currentUserIdProvider) != null;

  SupabaseClient get _client => _ref.read(supabaseClientProvider);
  LocalDb get _db => _ref.read(localDbProvider);

  Future<void> syncNow() async {
    if (!canSync) return;
    if (_inFlight) return;
    _inFlight = true;
    try {
      await _pushCards();
      await _pushWallet();
    } catch (_) {
      // Offline / server hiccup: rows stay dirty and retry on next trigger.
    } finally {
      _inFlight = false;
    }
  }

  bool _inFlight = false;

  Future<void> _pushCards() async {
    final userId = _ref.read(currentUserIdProvider)!;
    final pending = await _pendingDirtyCards(userId);
    for (final row in pending) {
      final payload = row.card.toRow()
        ..['user_id'] = userId; // owner id comes from the JWT on the server
      final existing = await _client
          .from('cards')
          .select('id')
          .eq('id', row.card.id)
          .maybeSingle();
      if (row.deleted) {
        await _client.from('cards').delete().eq('id', row.card.id);
      } else if (existing == null) {
        await _client.from('cards').upsert(payload);
      } else {
        payload.remove('short_code'); // immutable once issued
        await _client.from('cards').update(payload).eq('id', row.card.id);
      }
      // Social links live in their own table.
      if (!row.deleted) {
        await _client.from('card_links').delete().eq('card_id', row.card.id);
        if (row.card.socialLinks.isNotEmpty) {
          await _client.from('card_links').insert([
            for (var i = 0; i < row.card.socialLinks.length; i++)
              {
                'card_id': row.card.id,
                'type': row.card.socialLinks[i].type.name,
                'url': row.card.socialLinks[i].url,
                'sort_order': i,
              },
          ]);
        }
      }
      await _db.markLocalCardSynced(row.card.id);
    }
  }

  Future<void> _pushWallet() async {
    final dirtySaved = await _db.dirtySavedCards();
    for (final saved in dirtySaved) {
      await _client.from('saved_cards').upsert({
        'id': saved.id,
        'owner_user_id': _ref.read(currentUserIdProvider),
        'card_id': saved.cardId,
        'snapshot_json': saved.card.toJson(),
        'notes': saved.notes,
        'tags': saved.tags,
        'source': saved.source.name,
        'met_at': saved.metAt?.toUtc().toIso8601String(),
        'met_location': saved.metLocation,
        'saved_at': (saved.savedAt ?? DateTime.now()).toUtc().toIso8601String(),
      });
      await _db.markSavedSynced(saved.id);
    }
  }

  Future<List<_DirtyRow>> _pendingDirtyCards(String userId) async {
    final rows = await _db.dirtyLocalCards(userId);
    return rows
        .map((r) => _DirtyRow(
              card: Card.fromSnapshot(
                  (jsonDecode(r.snapshotJson) as Map).cast<String, dynamic>()),
              deleted: r.deleted,
            ))
        .toList();
  }
}

class _DirtyRow {
  const _DirtyRow({required this.card, required this.deleted});
  final Card card;
  final bool deleted;
}

final cardSyncServiceProvider = Provider<CardSyncService>(
  (ref) => CardSyncService(ref),
);
