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

@DriftDatabase(tables: [SavedCards])
class LocalDb extends _$LocalDb {
  LocalDb() : super(_openConnection());
  LocalDb.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

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
