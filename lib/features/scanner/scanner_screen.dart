import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/config/app_config.dart';
import '../../../app/l10n/app_strings.dart';
import '../../cards/domain/card_models.dart';
import '../../cards/domain/vcard_builder.dart';

/// Result types emitted by the scanner.
sealed class ScanResult {
  const ScanResult();
}

class ScanOnlineLink extends ScanResult {
  const ScanOnlineLink(this.shortCode);
  final String shortCode;
}

class ScanVCard extends ScanResult {
  const ScanVCard(this.card);
  final Card card;
}

class ScanUnknown extends ScanResult {
  const ScanUnknown(this.raw);
  final String raw;
  final Uri? uri = Uri.tryParse(raw);
}

/// Pure classifier for scanned QR payloads — unit tested.
ScanResult classifyScan(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('BEGIN:VCARD')) {
    final card = VCardBuilder.tryParseVCard(trimmed);
    if (card != null) return ScanVCard(card);
  }
  final uri = Uri.tryParse(trimmed);
  if (uri != null &&
      uri.hasScheme &&
      (uri.host == AppConfig.appLinkHost || uri.host.endsWith('.${AppConfig.appLinkHost}'))) {
    final segs = uri.pathSegments;
    if (segs.length >= 2 && segs[0] == 'c') {
      return ScanOnlineLink(segs[1]);
    }
  }
  return ScanUnknown(trimmed);
}

/// In-app QR scanner. Handles both online links and offline vCards.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key, this.onResult});

  /// If provided, screen pops with the result instead of navigating itself.
  final ValueChanged<ScanResult>? onResult;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;
    _handled = true;
    _controller.stop();
    final result = classifyScan(value);
    if (widget.onResult != null) {
      widget.onResult!(result);
    } else if (result is ScanOnlineLink) {
      Navigator.of(context).pushNamed('/received/${result.shortCode}');
    } else if (result is ScanVCard) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of(context).scanQr}: ${result.card.fullName}')),
      );
      Navigator.of(context).pop(result);
    } else {
      setState(() => _handled = false);
      _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.scanQr)),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.no_photography_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(strings.genericError, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
          // Scan window overlay
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
