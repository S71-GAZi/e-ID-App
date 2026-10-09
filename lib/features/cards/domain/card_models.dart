/// Pure-Dart domain models for cards. No Flutter imports here so they are
/// trivially unit-testable and reusable on any backend client code.
library;

import 'dart:convert';

/// Social link platforms supported out of the box (+ a custom type).
enum SocialLinkType {
  linkedin,
  facebook,
  instagram,
  x,
  whatsapp,
  telegram,
  youtube,
  github,
  custom;

  static SocialLinkType fromName(String name) =>
      values.firstWhere((e) => e.name == name, orElse: () => custom);

  String get displayName => switch (this) {
        SocialLinkType.x => 'X',
        SocialLinkType.custom => 'Custom',
        _ => name[0].toUpperCase() + name.substring(1),
      };
}

class SocialLink {
  const SocialLink({required this.type, required this.url});

  final SocialLinkType type;
  final String url;

  Map<String, dynamic> toJson() => {'type': type.name, 'url': url};

  factory SocialLink.fromJson(Map<String, dynamic> json) => SocialLink(
        type: SocialLinkType.fromName(json['type'] as String? ?? 'custom'),
        url: json['url'] as String? ?? '',
      );
}

/// Which fields are shared publicly / embedded in QR codes.
/// Default is visible = true; hidden fields are stripped everywhere
/// (public API payload, online & offline QR, vCard export).
class VisibilitySettings {
  const VisibilitySettings({
    this.title = true,
    this.company = true,
    this.phones = true,
    this.emails = true,
    this.website = true,
    this.address = true,
    this.bio = true,
    this.photo = true,
    this.socialLinks = true,
  });

  final bool title;
  final bool company;
  final bool phones;
  final bool emails;
  final bool website;
  final bool address;
  final bool bio;
  final bool photo;
  final bool socialLinks;

  Map<String, bool> toMap() => {
        'title': title,
        'company': company,
        'phones': phones,
        'emails': emails,
        'website': website,
        'address': address,
        'bio': bio,
        'photo': photo,
        'social_links': socialLinks,
      };

  factory VisibilitySettings.fromMap(Map<String, dynamic>? map) {
    bool flag(String key, [bool fallback = true]) =>
        (map?[key] as bool?) ?? fallback;
    return VisibilitySettings(
      title: flag('title'),
      company: flag('company'),
      phones: flag('phones'),
      emails: flag('emails'),
      website: flag('website'),
      address: flag('address'),
      bio: flag('bio'),
      photo: flag('photo'),
      socialLinks: flag('social_links'),
    );
  }
}

class Card {
  const Card({
    required this.id,
    required this.userId,
    required this.label,
    required this.fullName,
    this.title = '',
    this.company = '',
    this.phones = const [],
    this.emails = const [],
    this.website = '',
    this.address = '',
    this.bio = '',
    this.photoUrl,
    this.themeColor = '#3D5AFE',
    this.template = 'classic',
    this.visibility = const VisibilitySettings(),
    this.shortCode = '',
    this.isActive = true,
    this.socialLinks = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String label; // Work / Personal / …
  final String fullName;
  final String title;
  final String company;
  final List<String> phones;
  final List<String> emails;
  final String website;
  final String address;
  final String bio;
  final String? photoUrl;
  final String themeColor; // hex, e.g. #3D5AFE
  final String template; // classic | modern | minimal
  final VisibilitySettings visibility;
  final String shortCode; // unguessable public slug used in links
  final bool isActive;
  final List<SocialLink> socialLinks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Card copyWith({
    String? label,
    String? fullName,
    String? title,
    String? company,
    List<String>? phones,
    List<String>? emails,
    String? website,
    String? address,
    String? bio,
    String? photoUrl,
    bool clearPhoto = false,
    String? themeColor,
    String? template,
    VisibilitySettings? visibility,
    String? shortCode,
    bool? isActive,
    List<SocialLink>? socialLinks,
  }) =>
      Card(
        id: id,
        userId: userId,
        label: label ?? this.label,
        fullName: fullName ?? this.fullName,
        title: title ?? this.title,
        company: company ?? this.company,
        phones: phones ?? this.phones,
        emails: emails ?? this.emails,
        website: website ?? this.website,
        address: address ?? this.address,
        bio: bio ?? this.bio,
        photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
        themeColor: themeColor ?? this.themeColor,
        template: template ?? this.template,
        visibility: visibility ?? this.visibility,
        shortCode: shortCode ?? this.shortCode,
        isActive: isActive ?? this.isActive,
        socialLinks: socialLinks ?? this.socialLinks,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Row shape for the Supabase `cards` table.
  Map<String, dynamic> toRow() => {
        'id': id,
        'user_id': userId,
        'label': label,
        'full_name': fullName,
        'title': title,
        'company': company,
        'phones': phones,
        'emails': emails,
        'website': website,
        'address': address,
        'bio': bio,
        'photo_url': photoUrl,
        'theme': themeColor,
        'template': template,
        'visibility_settings': visibility.toMap(),
        'short_code': shortCode,
        'is_active': isActive,
      };

  factory Card.fromRow(Map<String, dynamic> row) => Card(
        id: row['id'] as String,
        userId: row['user_id'] as String? ?? '',
        label: row['label'] as String? ?? '',
        fullName: row['full_name'] as String? ?? '',
        title: row['title'] as String? ?? '',
        company: row['company'] as String? ?? '',
        phones: _stringList(row['phones']),
        emails: _stringList(row['emails']),
        website: row['website'] as String? ?? '',
        address: row['address'] as String? ?? '',
        bio: row['bio'] as String? ?? '',
        photoUrl: row['photo_url'] as String?,
        themeColor: row['theme'] as String? ?? '#3D5AFE',
        template: row['template'] as String? ?? 'classic',
        visibility: VisibilitySettings.fromMap(
            (row['visibility_settings'] as Map?)?.cast<String, dynamic>()),
        shortCode: row['short_code'] as String? ?? '',
        isActive: row['is_active'] as bool? ?? true,
        socialLinks: ((row['card_links'] as List?) ?? const [])
            .map((e) => SocialLink.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        createdAt: row['created_at'] != null
            ? DateTime.tryParse(row['created_at'] as String)
            : null,
        updatedAt: row['updated_at'] != null
            ? DateTime.tryParse(row['updated_at'] as String)
            : null,
      );

  /// JSON snapshot stored in `saved_cards.snapshot_json` (offline copy of a
  /// received card).
  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'full_name': fullName,
        'title': title,
        'company': company,
        'phones': phones,
        'emails': emails,
        'website': website,
        'address': address,
        'bio': bio,
        'photo_url': photoUrl,
        'theme': themeColor,
        'template': template,
        'short_code': shortCode,
        'social_links': socialLinks.map((l) => l.toJson()).toList(),
      };

  factory Card.fromJsonSnapshot(Map<String, dynamic> j) => Card(
        id: j['id'] as String? ?? '',
        userId: '',
        label: j['label'] as String? ?? '',
        fullName: j['full_name'] as String? ?? '',
        title: j['title'] as String? ?? '',
        company: j['company'] as String? ?? '',
        phones: _stringList(j['phones']),
        emails: _stringList(j['emails']),
        website: j['website'] as String? ?? '',
        address: j['address'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        photoUrl: j['photo_url'] as String?,
        themeColor: j['theme'] as String? ?? '#3D5AFE',
        template: j['template'] as String? ?? 'classic',
        shortCode: j['short_code'] as String? ?? '',
        socialLinks: ((j['social_links'] as List?) ?? const [])
            .map((e) => SocialLink.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
      );

  static List<String> _stringList(dynamic v) =>
      (v as List?)?.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() ??
      const [];
}

/// A card saved into the local wallet by scanning/receiving.
class SavedCard {
  const SavedCard({
    required this.id,
    required this.ownerUserId,
    required this.card,
    this.cardId,
    this.notes = '',
    this.tags = const [],
    this.metAt,
    this.metLocation = '',
    required this.source,
    this.savedAt,
  });

  final String id;
  final String ownerUserId;
  final String? cardId; // null for pure-offline vCard-only entries
  final Card card; // snapshot
  final String notes;
  final List<String> tags;
  final DateTime? metAt;
  final String metLocation;
  final SavedCardSource source;
  final DateTime? savedAt;

  SavedCard copyWith({String? notes, List<String>? tags, DateTime? metAt, String? metLocation}) =>
      SavedCard(
        id: id,
        ownerUserId: ownerUserId,
        cardId: cardId,
        card: card,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
        metAt: metAt ?? this.metAt,
        metLocation: metLocation ?? this.metLocation,
        source: source,
        savedAt: savedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_user_id': ownerUserId,
        'card_id': cardId,
        'snapshot_json': card.toJson(),
        'notes': notes,
        'tags': tags,
        'met_at': metAt?.toIso8601String(),
        'met_location': metLocation,
        'source': source.name,
        'saved_at': savedAt?.toIso8601String(),
      };

  factory SavedCard.fromJson(Map<String, dynamic> j) => SavedCard(
        id: j['id'] as String,
        ownerUserId: j['owner_user_id'] as String? ?? '',
        cardId: j['card_id'] as String?,
        card: Card.fromJsonSnapshot(
            (j['snapshot_json'] as Map).cast<String, dynamic>()),
        notes: j['notes'] as String? ?? '',
        tags: _decodeStringList(j['tags']),
        metAt: j['met_at'] != null ? DateTime.tryParse(j['met_at'] as String) : null,
        metLocation: j['met_location'] as String? ?? '',
        source: SavedCardSource.values.firstWhere(
          (e) => e.name == j['source'],
          orElse: () => SavedCardSource.qrOnline,
        ),
        savedAt:
            j['saved_at'] != null ? DateTime.tryParse(j['saved_at'] as String) : null,
      );

  static List<String> _decodeStringList(dynamic v) {
    if (v == null) return const [];
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String) {
      try {
        return (jsonDecode(v) as List).map((e) => e.toString()).toList();
      } catch (_) {
        return v.split(',').where((s) => s.trim().isNotEmpty).toList();
      }
    }
    return const [];
  }
}

enum SavedCardSource { qrOnline, qrOffline, nfc, nearby, manual }
