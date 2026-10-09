import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_strings.dart';
import '../wallet/domain/wallet_providers.dart';

/// Screen shown when a shared link (https://…/c/<shortCode>) is opened —
/// either via deep link into the app or from an in-app scan.
///
/// Phase 3 wires this up fully: it fetches the public card by short code,
/// applies field visibility, and offers "Save to my wallet". For now it
/// saves the scanned snapshot directly when one was passed by the scanner.
class ReceivedCardScreen extends ConsumerStatefulWidget {
  const ReceivedCardScreen({
    super.key,
    required this.shortCode,
    this.snapshotJson,
  });

  final String shortCode;

  /// Optional vCard/JSON snapshot captured offline (scanner flow) so the
  /// screen works without network access.
  final String? snapshotJson;

  @override
  ConsumerState<ReceivedCardScreen> createState() =>
      _ReceivedCardScreenState();
}

class _ReceivedCardScreenState extends ConsumerState<ReceivedCardScreen> {
  bool _saving = false;

  Future<void> _saveToWallet() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppStrings.of(context);
    try {
      await ref
          .read(walletControllerProvider.notifier)
          .saveFromShortCode(widget.shortCode, snapshotJson: widget.snapshotJson);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(strings.saved)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(strings.networkError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.scanQr)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search_rounded,
                  size: 72, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                '${strings.tabMyCards}: ${widget.shortCode}',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _saveToWallet,
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.account_balance_wallet_rounded),
                label: Text(strings.saveToWallet),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
