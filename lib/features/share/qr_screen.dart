import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/config/app_config.dart';
import '../../../app/l10n/app_strings.dart';
import '../../cards/domain/card_models.dart';
import '../../cards/domain/vcard_builder.dart';

/// QR screen with Online/Offline toggle, brightness boost and keep-screen-on
/// while visible. Online = short link; Offline = embedded vCard (auto size
/// check with graceful fallback).
class QrScreen extends ConsumerStatefulWidget {
  const QrScreen({super.key, required this.card});

  final Card card;

  @override
  ConsumerState<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends ConsumerState<QrScreen> {
  bool _offline = false;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  String get _payload {
    if (!_offline) return VCardBuilder.onlineQrPayload(widget.card);
    final trimmed = VCardBuilder.trimmedForOfflineQr(widget.card);
    if (trimmed == null) {
      // Too large even after trimming → fall back to online automatically.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _offline) setState(() => _offline = false);
      });
      return VCardBuilder.onlineQrPayload(widget.card);
    }
    return VCardBuilder.buildVCard(trimmed);
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _payload));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).linkCopied)));
    }
  }

  Future<void> _shareText() => Share.share(_payload, subject: widget.card.fullName);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final payload = _payload;
    final isOnline = !_offline;

    return Scaffold(
      appBar: AppBar(title: Text(strings.showQr)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(strings.onlineMode)),
                  ButtonSegment(value: true, label: Text(strings.offlineMode)),
                ],
                selected: {_offline},
                onSelectionChanged: (s) => setState(() => _offline = s.first),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  isOnline
                      ? '${AppConfig.publicBaseUrl}/c/${widget.card.shortCode}'
                      : '${VCardBuilder.byteLength(payload)} B / ${AppConfig.maxOfflineQrBytes} B',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: QrImageView(
                      key: _qrKey,
                      data: payload,
                      version: QrVersions.auto,
                      size: 280,
                      gapless: true,
                      backgroundColor: Colors.white,
                      semanticsLabel: strings.showQr,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.qrBrightnessHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyLink,
                      icon: const Icon(Icons.copy_rounded),
                      label: Text(strings.copyLink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _shareText,
                      icon: const Icon(Icons.ios_share_rounded),
                      label: Text(MaterialLocalizations.of(context).shareWidgetLabel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
