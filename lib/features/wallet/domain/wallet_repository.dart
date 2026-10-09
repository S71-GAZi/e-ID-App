import 'package:drift/drift.dart';

import '../../../core/storage/local_db.dart';
import '../../cards/domain/card_models.dart';

/// Offline-first wallet repository. Writes go to Drift immediately (flagged
/// `dirty`); a sync pass pushes them to Supabase when online (Phase 2 wires
/// the remote upsert; here we keep the queue semantics).
class WalletRepository {
  WalletRepository(this._db);

  final LocalDb _db;

  Stream<List<SavedCard>> watchSavedCards() => _db.watchSavedCards();

  Future<void> save(SavedCard card) => _db.upsertSaved(card);

  Future<void> delete(String id) async {
    await _db.deleteSaved(id);
    // TODO(Phase 2): also delete remote row when synced.
  }

  Future<List<SavedCard>> pendingSync() async {
    return (await _db.allSavedCards()).where((c) => true).toList();
  }

  /// Rows flagged dirty are queued for upload whenever connectivity returns.
  Future<int> dirtyCount() async =>
      (_db.select(_db.savedCards)..where((t) => t.dirty)).get().then((rows) => rows.length);
}
