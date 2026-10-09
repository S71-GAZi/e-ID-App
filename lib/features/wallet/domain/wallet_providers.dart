import 'package:flutter_riverpod/flutter_riverpod.dart';

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
