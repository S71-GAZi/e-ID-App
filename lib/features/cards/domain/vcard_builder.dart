import 'dart:convert';

import '../../app/config/app_config.dart';
import 'card_models.dart';

/// Builds vCard 3.0 payloads and QR contents, respecting visibility settings.
///
/// Pure Dart — unit tested in test/unit/vcard_builder_test.dart.
class VCardBuilder {
  const VCardBuilder._();

  /// Returns a copy of [card] containing only the fields marked visible.
  static Card applyVisibility(Card card) {
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

  /// vCard 3.0 string (CRLF line endings per RFC 2426).
  ///
  /// Photo is intentionally NOT embedded: base64 images blow past the QR
  /// size limit fast. The URL form (`photo_url`) is included instead when
  /// available.
  static String buildVCard(Card card) {
    final c = applyVisibility(card);
    final lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'N:${_escape(_lastName(c.fullName))};${_escape(_firstName(c.fullName))};;;',
      'FN:${_escape(c.fullName)}',
      if (c.title.isNotEmpty) 'TITLE:${_escape(c.title)}',
      if (c.company.isNotEmpty) 'ORG:${_escape(c.company)}',
    ];

    for (final phone in c.phones) {
      lines.add('TEL;TYPE=CELL:${_escape(phone)}');
    }
    for (final email in c.emails) {
      lines.add('EMAIL;TYPE=INTERNET:${_escape(email)}');
    }
    if (c.website.isNotEmpty) lines.add('URL:${_escape(c.website)}');
    if (c.address.isNotEmpty) {
      lines.add('ADR;TYPE=WORK:;;${_escape(c.address)};;;;');
      lines.add('LABEL;TYPE=WORK:${_escape(c.address)}');
    }
    if (c.bio.isNotEmpty) lines.add('NOTE:${_escape(c.bio)}');
    if (c.photoUrl != null && c.photoUrl!.isNotEmpty) {
      lines.add('PHOTO;VALUE=URI:${_escape(c.photoUrl!)}');
    }
    for (final link in c.socialLinks) {
      if (link.url.trim().isEmpty) continue;
      lines.add('X-SOCIALPROFILE;TYPE=${link.type.name}:${_escape(link.url)}');
    }
    // Our own extension so the app can re-identify the card after scanning.
    if (c.shortCode.isNotEmpty) lines.add('X-SMARTCARD:${c.shortCode}');
    lines.add('REV:${DateTime.now().toUtc().toIso8601String()}');
    lines.add('END:VCARD');
    return lines.join('\r\n');
  }

  /// Online share QR content: https://<domain>/c/<shortCode>
  static String onlineQrPayload(Card card) =>
      '${AppConfig.publicBaseUrl}/c/${card.shortCode}';

  /// Offline share QR content: raw vCard text.
  static String offlineQrPayload(Card card) => buildVCard(card);

  static int byteLength(String s) => utf8.encode(s).length;

  /// True when the offline payload fits within our conservative QR budget.
  static bool fitsOfflineQr(Card card) =>
      byteLength(offlineQrPayload(card)) <= AppConfig.maxOfflineQrBytes;

  /// Greedy trim used when a card is too big for an offline QR: drops bio,
  /// address and secondary contacts until it fits. Returns null if even the
  /// minimal set does not fit (caller should fall back to the online QR).
  static Card? trimmedForOfflineQr(Card card) {
    var c = applyVisibility(card);
    if (byteLength(buildVCard(c)) <= AppConfig.maxOfflineQrBytes) return c;

    c = c.copyWith(bio: '', address: '');
    if (byteLength(buildVCard(c)) <= AppConfig.maxOfflineQrBytes) return c;

    c = c.copyWith(socialLinks: const []);
    if (byteLength(buildVCard(c)) <= AppConfig.maxOfflineQrBytes) return c;

    // Keep only the first phone/email each.
    c = c.copyWith(
      phones: c.phones.isEmpty ? const [] : [c.phones.first],
      emails: c.emails.isEmpty ? const [] : [c.emails.first],
    );
    if (byteLength(buildVCard(c)) <= AppConfig.maxOfflineQrBytes) return c;

    return null; // still too large → online fallback
  }

  /// Parse the subset of vCard we generate (and common camera-app vCards).
  /// Used by the in-app scanner when a raw vCard QR is detected.
  static Card? tryParseVCard(String input) {
    final text = input.trim();
    if (!text.startsWith('BEGIN:VCARD')) return null;
    final lines = text.split(RegExp(r'\r\n|\n'));
    var fullName = '';
    var title = '';
    var company = '';
    var website = '';
    var address = '';
    var bio = '';
    var photoUrl = '';
    var shortCode = '';
    final phones = <String>[];
    final emails = <String>[];
    final links = <SocialLink>[];

    for (final raw in lines) {
      final sep = raw.indexOf(':');
      if (sep < 0) continue;
      final keyPart = raw.substring(0, sep);
      final value = _unescape(raw.substring(sep + 1));
      final key = keyPart.split(';').first.toUpperCase();
      switch (key) {
        case 'FN':
          fullName = value;
        case 'TITLE':
          title = value;
        case 'ORG':
          company = value.split(';').first;
        case 'TEL':
          if (value.isNotEmpty) phones.add(value);
        case 'EMAIL':
          if (value.isNotEmpty) emails.add(value);
        case 'URL':
          website = value;
        case 'ADR':
        case 'LABEL':
          if (address.isEmpty) {
            address = value.replaceAll(';', ' ').trim();
          }
        case 'NOTE':
          bio = value;
        case 'PHOTO':
          if (value.startsWith('http')) photoUrl = value;
        case 'X-SMARTCARD':
          shortCode = value;
        case 'X-SOCIALPROFILE':
          final typeRaw = keyPart.contains('TYPE=')
              ? keyPart.split('TYPE=').last.split(';').first
              : 'custom';
          links.add(SocialLink(
              type: SocialLinkType.fromName(typeRaw.toLowerCase()), url: value));
      }
    }
    if (fullName.isEmpty && phones.isEmpty && emails.isEmpty) return null;
    return Card(
      id: 'vcf-${DateTime.now().microsecondsSinceEpoch}',
      userId: '',
      label: '',
      fullName: fullName,
      title: title,
      company: company,
      phones: phones,
      emails: emails,
      website: website,
      address: address,
      bio: bio,
      photoUrl: photoUrl.isEmpty ? null : photoUrl,
      shortCode: shortCode,
      socialLinks: links,
    );
  }

  // ---- helpers ----

  static String _firstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.length <= 1 ? name : parts.skip(1).join(' ');
  }

  static String _lastName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  /// vCard escaping: backslash-escape , ; \ and newlines.
  static String _escape(String s) => s
      .replaceAll('\\', r'\\')
      .replaceAll(',', r'\,')
      .replaceAll(';', r'\;')
      .replaceAll('\n', r'\n');

  static String _unescape(String s) => s
      .replaceAll(r'\,', ',')
      .replaceAll(r'\;', ';')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\\', r'\');
}
