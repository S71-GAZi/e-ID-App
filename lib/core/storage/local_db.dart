import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../../features/cards/domain/card_models.dart' as m;
import '../../features/cards/domain/card_models.dart' show SavedCard;

part 'local_db.g.dart';

/// Simple key/value table for app-level state (local account, onboarding
/// flag, last sync timestamps…).
class AppMeta extends Table {
  TextColumn get metaKey => text()();
  TextColumn get metaValue => text()();

  @override
  Set<Column> get primaryKey => {metaKey};
}

/// Local mirror of the user's own cards. Offline-first: every create/edit
/// writes here immediately and is flagged `dirty`; the sync service pushes
/// changes to Supabase when a session + connectivity are available.
class LocalCards extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get snapshotJson => text()(); // Card.toJson() + extras
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table mirroring `saved_cards` for offline-first wallet storage.
class SavedCards extends Table {
  TextColumn get id => text()();
  TextColumn get ownerUserId => text()();
  TextColumn get cardId => text().nullable()();
  TextColumn get snapshotJson => text()(); // Card.toJson() encoded
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get source => text()();
  TextColumn get metAt => dateTime().nullable()();
  TextColumn get metLocation => text().withDefault(const Constant(''))();
  TextColumn get savedAt => dateTime()();
  TextColumn get dirty => boolean().withDefault(const Constant(false))(); // queued sync

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [AppMeta, LocalCards, SavedCards])
class LocalDb extends _$LocalDb {
  LocalDb() : super(_openConnection());
  LocalDb.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  // ---- app_meta key/value ----

  String? getMeta(String key) {
    final row = (select(appMeta)..where((t) => t.metaKey.equals(key)))
        .getSingleSync();
    return row?.metaValue;
  }

  Future<void> setMeta(String key, String value) =>
      into(appMeta).insertOnConflictUpdate(
          AppMetaCompanion.insert(metaKey: key, metaValue: value));

  Future<void> deleteMeta(String key) =>
      (delete(appMeta)..where((t) => t.metaKey.equals(key))).go();

  // ---- local cards (offline-first mirror of the user's own cards) ----

  /// Full snapshot including visibility/theme/isActive — stored as one JSON
  /// blob so Card model changes never require a DB migration.
  Future<void> upsertLocalCard(m.Card card) =>
      into(localCards).insertOnConflictUpdate(LocalCardsCompanion.insert(
        id: card.id,
        userId: card.userId,
        snapshotJson: jsonEncode(card.toSnapshot()),
        isActive: Value(card.isActive),
        updatedAt: DateTime.now(),
        dirty: const Value(true),
      ));

  Stream<List<m.Card>> watchLocalCards(String userId) =>
      (select(localCards)
            ..where((t) => t.userId.equals(userId) & t.deleted.equals(false))
            ..orderBy([(t) => t.updatedAt.desc()]))
          .watch()
          .map((rows) => rows.map(_cardFromRow).toList());

  List<m.Card> localCardsOf(String userId) =>
      (select(localCards)
            ..where((t) => t.userId.equals(userId) & t.deleted.equals(false))
            ..orderBy([(t) => t.updatedAt.desc()]))
          .get()
          .then((rows) => rows.map(_cardFromRow).toList());

  Future<void> markLocalCardDeleted(String id) =>
      (update(localCards)..where((t) => t.id.equals(id))).write(
          const LocalCardsCompanion(deleted: Value(true), dirty: Value(true)));

  Future<void> setLocalCardActive(String id, bool active) async {
    final row = await (select(localCards)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    final map = (jsonDecode(row.snapshotJson) as Map).cast<String, dynamic>();
    map['is_active'] = active;
    await into(localCards).insertOnConflictUpdate(LocalCardsCompanion.insert(
      id: id,
      userId: row.userId,
      snapshotJson: jsonEncode(map),
      isActive: Value(active),
      updatedAt: DateTime.now(),
      dirty: const Value(true),
    ));
  }

  m.Card _cardFromRow(DriftLocalCard row) => m.Card.fromSnapshot(
      (jsonDecode(row.snapshotJson) as Map).cast<String, dynamic>());

  Future<List<DriftLocalCard>> dirtyLocalCards(String userId) =>
      (select(localCards)
            ..where((t) => t.userId.equals(userId) & t.dirty.equals(true)))
          .get();

  Future<void> markLocalCardSynced(String id) =>
      (update(localCards)..where((t) => t.id.equals(id))).write(
          const LocalCardsCompanion(dirty: Value(false)));

  // ---- saved cards (wallet) ----

  Future<List<SavedCard>> allSavedCards() async {
    final rows = await (select(savedCards)..orderBy([(t) => t.savedAt.desc()])).get();
    return rows.map(_toModel).toList();
  }

  Stream<List<SavedCard>> watchSavedCards() {
    return (select(savedCards)..orderBy([(t) => t.savedAt.desc()]))
        .watch()
        .map((rows) => rows.map(_toModel).toList());
  }

  Future<void> upsertSaved(SavedCard s) => into(savedCards).insertOnConflictUpdate(
        SavedCardsCompanion.insert(
          id: s.id,
          ownerUserId: s.ownerUserId,
          cardId: Value(s.cardId),
          snapshotJson: jsonEncode(s.card.toJson()),
          notes: Value(s.notes),
          tags: Value(jsonEncode(s.tags)),
          source: s.source.name,
          metAt: Value(s.metAt),
          metLocation: Value(s.metLocation),
          savedAt: s.savedAt ?? DateTime.now(),
          dirty: const Value(true),
        ),
      );

  Future<void> deleteSaved(String id) =>
      (delete(savedCards)..where((t) => t.id.equals(id))).go();

  Future<List<SavedCard>> dirtySavedCards() async {
    final rows = await (select(savedCards)..where((t) => t.dirty)).get();
    return rows.map(_toModel).toList();
  }

  Future<void> markSavedSynced(String id) =>
      (update(savedCards)..where((t) => t.id.equals(id)))
          .write(const SavedCardsCompanion(dirty: Value(false)));

  DriftSavedCard _toModel(DriftSavedCard row_) => SavedCard(
        id: row_.id,
        ownerUserId: row_.ownerUserId,
        cardId: row_.cardId,
        card: Card.fromJsonSnapshot(
            (jsonDecode(row_.snapshotJson) as Map).cast<String, dynamic>()),
        notes: row_.notes,
        tags: (jsonDecode(row_.tags) as List).cast<String>(),
        source: SavedCardSource.values.firstWhere((e) => e.name == row_.source,
            orElse: () => SavedCardSource.qrOnline),
        metAt: row_.metAt,
        metLocation: row_.metLocation,
        savedAt: row_.savedAt,
      );
}

LazyDatabase _openConnection() => LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'smart_card.sqlite'));
      return NativeDatabase.createInBackground(file);
});

final localDbProvider = Provider<LocalDb>((ref) {
  final db = LocalDb();
  ref.onDispose(db.close);
  return db;
});
