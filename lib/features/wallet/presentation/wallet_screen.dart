import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_strings.dart';
import '../../cards/domain/card_models.dart';
import '../../cards/presentation/card_preview.dart';
import '../domain/wallet_providers.dart';

/// Wallet: cards the user has received, with search and swipe-to-delete.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final savedAsync = ref.watch(savedCardsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.tabWallet)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: strings.searchCards,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: savedAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => EmptyState(icon: Icons.cloud_off, message: strings.networkError),
              data: (items) {
                final filtered = items.where((s) {
                  if (_query.isEmpty) return true;
                  final c = s.card;
                  return [c.fullName, c.company, c.title, ...s.tags]
                      .join(' ')
                      .toLowerCase()
                      .contains(_query);
                }).toList();
                if (filtered.isEmpty) {
                  return EmptyState(
                      icon: Icons.account_balance_wallet_outlined, message: strings.walletEmpty);
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) => _SavedCardTile(saved: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedCardTile extends ConsumerWidget {
  const _SavedCardTile({required this.saved});

  final SavedCard saved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(saved.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => ref.read(walletRepositoryProvider).delete(saved.id),
      child: CardPreview(card: saved.card),
    );
  }
}
