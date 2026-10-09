import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/theme/app_theme.dart';
import '../domain/card_models.dart';

/// Renders a digital business card. Three templates (classic / modern /
/// minimal) share one widget and differ only in layout, so the live preview
/// in the editor is exactly what receivers see.
class CardPreview extends StatelessWidget {
  const CardPreview({super.key, required this.card, this.photoBytes});

  final Card card;
  final Uint8List? photoBytes;

  Color get _accent {
    final hex = card.themeColor.replaceFirst('#', '');
    if (hex.length == 6) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (card.template) {
      'modern' => _buildModern(context, dark),
      'minimal' => _buildMinimal(context, dark),
      _ => _buildClassic(context, dark),
    };
  }

  Widget _avatar(double size, {bool onAccent = false}) {
    final fg = onAccent ? Colors.white : Theme.of(context).colorScheme.onSurface;
    if (photoBytes != null) {
      return ClipOval(
        child: Image.memory(photoBytes!, width: size, height: size, fit: BoxFit.cover),
      );
    }
    if (card.visibility.photo && card.photoUrl != null && card.photoUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          card.photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(size, fg),
        ),
      );
    }
    return _initialsAvatar(size, fg);
  }

  Widget _initialsAvatar(double size, Color fg) {
    final initials = card.fullName.trim().isEmpty
        ? '?'
        : card.fullName
            .split(RegExp(r'\s+'))
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _accent.withOpacity(0.15),
      child: Text(initials, style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
    );
  }

  Widget _nameBlock(BuildContext context, {bool light = false}) {
    final base = light ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final sub = light ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(
            card.fullName,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: base),
          ),
        ),
        if (card.visibility.title && card.title.isNotEmpty)
          Text(card.title, style: TextStyle(fontSize: 14, color: sub)),
        if (card.visibility.company && card.company.isNotEmpty)
          Text(card.company, style: TextStyle(fontSize: 13, color: sub)),
      ],
    );
  }

  List<Widget> _contactRows(BuildContext context, {bool light = false}) {
    final sub = light ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant;
    final visible = VCardFilter.visible(card);
    Widget row(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Icon(icon, size: 16, color: light ? Colors.white70 : _accent),
            const SizedBox(width: 8),
            Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: sub))),
          ]),
        );
    return [
      for (final p in visible.phones) row(Icons.phone_outlined, p),
      for (final e in visible.emails) row(Icons.mail_outline_rounded, e),
      if (visible.website.isNotEmpty) row(Icons.language_rounded, visible.website),
      if (visible.address.isNotEmpty) row(Icons.place_outlined, visible.address),
    ];
  }

  Widget _buildClassic(BuildContext context, bool dark) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accent, _accent.withOpacity(dark ? 0.65 : 0.85)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(56, onAccent: true),
                const SizedBox(width: 14),
                Expanded(child: _nameBlock(context, light: true)),
                if (card.label.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(card.label,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ..._contactRows(context, light: true),
            if (card.visibility.bio && card.bio.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(card.bio,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModern(BuildContext context, bool dark) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 84,
            decoration: BoxDecoration(color: _accent),
            alignment: Alignment.center,
            child: Text(card.fullName.split(' ').take(2).join(' '),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: _avatar(56),
          ),
           Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  _nameBlock(context),
                  const SizedBox(height: 12),
                  ..._contactRows(context),
                  if (card.visibility.socialLinks && card.socialLinks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final l in card.socialLinks)
                            Chip(
                              label: Text(l.type.displayName, style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimal(BuildContext context, bool dark) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _avatar(44),
                const SizedBox(width: 12),
                Expanded(child: _nameBlock(context)),
              ],
            ),
            const Divider(height: 28),
            ..._contactRows(context),
          ],
        ),
      ),
    );
  }
}

/// Small helper so previews/QR use the same visibility filter as sharing.
class VCardFilter {
  static Card visible(Card card) {
    final v = card.visibility;
    return card.copyWith(
      title: v.title ? card.title : '',
      company: v.company ? card.company : '',
      phones: v.phones ? card.phones : const [],
      emails: v.emails ? card.emails : const [],
      website: v.website ? card.website : '',
      address: v.address ? card.address : '',
      bio: v.bio ? card.bio : '',
      photoUrl: v.photo ? card.photoUrl : null,
      socialLinks: v.socialLinks ? card.socialLinks : const [],
    );
  }
}

/// Shared "empty state" widget.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(message.isEmpty ? strings.genericError : message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
