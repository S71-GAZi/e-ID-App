import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_strings.dart';
import '../../auth/data/supabase_providers.dart';
import '../data/card_repository.dart';
import '../domain/card_models.dart';
import 'card_editor_screen.dart';
import 'card_preview.dart';

/// Home screen: list of the user's cards with create/edit/deactivate actions.
class MyCardsScreen extends ConsumerWidget {
  const MyCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return EmptyState(icon: Icons.lock_outline, message: strings.signIn);
    }

    final cardsAsync = ref.watch(userCardsStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.tabMyCards),
        actions: [
          IconButton(
            tooltip: strings.settings,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: cardsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.cloud_off, message: strings.networkError),
        data: (cards) {
          if (cards.isEmpty) {
            return EmptyState(icon: Icons.credit_card_outlined, message: strings.newCard);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _CardTile(card: cards[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-card',
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const CardEditorScreen(),
        )),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.newCard),
      ),
    );
  }
}

class _CardTile extends ConsumerWidget {
  const _CardTile({required this.card});

  final Card card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    return Column(
      children: [
        Stack(
          children: [
            CardPreview(card: card),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<String>(
                onSelected: (v) async {
                  final repo = ref.read(cardRepositoryProvider);
                  switch (v) {
                    case 'edit':
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => CardEditorScreen(existing: card),
                      ));
                    case 'toggle':
                      await repo.setActive(card.id, !card.isActive);
                    case 'delete':
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(strings.delete),
                          content: Text(card.fullName),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: Text(strings.cancel)),
                            FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(strings.delete)),
                          ],
                        ),
                      );
                      if (ok == true) await repo.deleteCard(card.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(strings.editCard)),
                  PopupMenuItem(
                      value: 'toggle',
                      child: Text(card.isActive ? strings.hidden : strings.visibleToOthers)),
                  PopupMenuItem(value: 'delete', child: Text(strings.delete)),
                ],
              ),
            ),
          ],
        ),
        if (!card.isActive)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('⛔ ${strings.hidden}',
                style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }
}
