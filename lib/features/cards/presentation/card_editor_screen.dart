import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/theme/app_theme.dart';
import '../data/card_repository.dart';
import '../domain/card_models.dart';
import '../domain/vcard_builder.dart';
import 'card_preview.dart';

/// Editor for creating/updating a card, with live preview, per-field
/// visibility toggles, social links, photo and theme selection.
class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key, this.existing});

  final Card? existing; // null → create mode

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late Card _draft;
  Uint8List? _photoBytes;
  bool _saving = false;

  final _labelCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final List<TextEditingController> _phoneCtrls = [];
  final List<TextEditingController> _emailCtrls = [];
  final List<_SocialLinkDraft> _links = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _draft = e ??
        Card(
          id: const Uuid().v4(),
          userId: '',
          label: AppStrings.en.work,
          fullName: '',
        );
    _labelCtrl.text = _draft.label;
    _nameCtrl.text = _draft.fullName;
    _titleCtrl.text = _draft.title;
    _companyCtrl.text = _draft.company;
    _websiteCtrl.text = _draft.website;
    _addressCtrl.text = _draft.address;
    _bioCtrl.text = _draft.bio;
    for (final p in _draft.phones) _phoneCtrls.add(TextEditingController(text: p));
    if (_phoneCtrls.isEmpty) _phoneCtrls.add(TextEditingController());
    for (final m in _draft.emails) _emailCtrls.add(TextEditingController(text: m));
    if (_emailCtrls.isEmpty) _emailCtrls.add(TextEditingController());
    for (final l in _draft.socialLinks) {
      _links.add(_SocialLinkDraft(type: l.type, url: TextEditingController(text: l.url)));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _labelCtrl, _nameCtrl, _titleCtrl, _companyCtrl, _websiteCtrl, _addressCtrl, _bioCtrl,
      ..._phoneCtrls, ..._emailCtrls,
      for (final l in _links) l.url,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Card _composeDraft() {
    return _draft.copyWith(
      label: _labelCtrl.text.trim().isEmpty ? 'Work' : _labelCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      company: _companyCtrl.text.trim(),
      phones: _phoneCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
      emails: _emailCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
      website: _normalizeUrl(_websiteCtrl.text.trim()),
      address: _addressCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      socialLinks: _links
          .where((l) => l.url.text.trim().isNotEmpty)
          .map((l) => SocialLink(type: l.type, url: _normalizeUrl(l.url.text.trim())))
          .toList(),
    );
  }

  static String _normalizeUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return 'https://$raw';
  }

  void _refreshPreview() => setState(() {});

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 82);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    setState(() => _photoBytes = bytes);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final draft = _composeDraft();
      final repo = ref.read(cardRepositoryProvider);
      if (widget.existing == null) {
        await repo.createCard(draft);
      } else {
        await repo.updateCard(draft);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).genericError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final preview = _composeDraft();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? strings.newCard : strings.editCard),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            tooltip: strings.save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: [
            // ---- Live preview ----
            CardPreview(card: preview, photoBytes: _photoBytes),
            const SizedBox(height: 24),

            // ---- Basics ----
            TextFormField(
              controller: _labelCtrl,
              decoration: InputDecoration(labelText: strings.cardLabel),
              onChanged: (_) => _refreshPreview(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: strings.fullName),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? strings.validationRequired : null,
              onChanged: (_) => _refreshPreview(),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(labelText: strings.jobTitle),
                  onChanged: (_) => _refreshPreview(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _companyCtrl,
                  decoration: InputDecoration(labelText: strings.company),
                  onChanged: (_) => _refreshPreview(),
                ),
              ),
            ]),

            _SectionHeader(title: strings.photo, icon: Icons.person_outline),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(strings.takePhoto),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(strings.chooseFromGallery),
                ),
                if (_photoBytes != null || _draft.photoUrl != null)
                  IconButton(
                    onPressed: () => setState(() {
                      _photoBytes = null;
                      _draft = _draft.copyWith(clearPhoto: true);
                    }),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: strings.delete,
                  ),
              ],
            ),

            _SectionHeader(title: strings.phone, icon: Icons.phone_outlined),
            for (var i = 0; i < _phoneCtrls.length; i++)
              _RepeatField(
                controller: _phoneCtrls[i],
                keyboardType: TextInputType.phone,
                hint: '+1 555 0100',
                canRemove: _phoneCtrls.length > 1,
                onRemove: () => setState(() => _phoneCtrls.removeAt(i)),
                onChanged: (_) => _refreshPreview(),
              ),
            _AddFieldLink(onTap: () => setState(() => _phoneCtrls.add(TextEditingController()))),

            _SectionHeader(title: strings.emailAddress, icon: Icons.mail_outline_rounded),
            for (var i = 0; i < _emailCtrls.length; i++)
              _RepeatField(
                controller: _emailCtrls[i],
                keyboardType: TextInputType.emailAddress,
                hint: 'you@company.com',
                canRemove: _emailCtrls.length > 1,
                onRemove: () => setState(() => _emailCtrls.removeAt(i)),
                onChanged: (_) => _refreshPreview(),
              ),
            _AddFieldLink(onTap: () => setState(() => _emailCtrls.add(TextEditingController()))),

            _SectionHeader(title: strings.website, icon: Icons.language_rounded),
            TextFormField(
              controller: _websiteCtrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: 'https://yoursite.com',
                labelText: strings.website,
              ),
              validator: _urlValidator(strings),
              onChanged: (_) => _refreshPreview(),
            ),

            _SectionHeader(title: strings.address, icon: Icons.place_outlined),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: InputDecoration(labelText: strings.address),
              onChanged: (_) => _refreshPreview(),
            ),

            _SectionHeader(title: strings.bio, icon: Icons.notes_rounded),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 280,
              decoration: InputDecoration(labelText: strings.bio),
              onChanged: (_) => _refreshPreview(),
            ),

            _SectionHeader(title: strings.socialLinks, icon: Icons.link_rounded),
            for (final link in _links)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    DropdownButton<SocialLinkType>(
                      value: link.type,
                      items: [
                        for (final t in SocialLinkType.values)
                          DropdownMenuItem(value: t, child: Text(t.displayName)),
                      ],
                      onChanged: (t) => setState(() => link.type = t ?? link.type),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: link.url,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(hintText: 'https://…'),
                        validator: _urlValidator(strings),
                        onChanged: (_) => _refreshPreview(),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _links.remove(link)),
                      icon: const Icon(Icons.remove_circle_outline),
                      tooltip: strings.delete,
                    ),
                  ],
                ),
              ),
            _AddFieldLink(
              onTap: () => setState(() => _links.add(_SocialLinkDraft(
                  type: SocialLinkType.linkedin, url: TextEditingController()))),
            ),

            _SectionHeader(title: strings.theme, icon: Icons.palette_outlined),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in AppColors.cardAccents)
                  ChoiceChip(
                    selected: _draft.themeColor.toUpperCase() ==
                        '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
                    onSelected: (_) => setState(() => _draft =
                        _draft.copyWith(themeColor: '#${color.value.toRadixString(16).substring(2)}')),
                    avatar: CircleAvatar(backgroundColor: color, radius: 8),
                    label: const SizedBox.shrink(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'classic', label: Text('Classic')),
                ButtonSegment(value: 'modern', label: Text('Modern')),
                ButtonSegment(value: 'minimal', label: Text('Minimal')),
              ],
              selected: {_draft.template},
              onSelectionChanged: (s) =>
                  setState(() => _draft = _draft.copyWith(template: s.first)),
            ),

            _SectionHeader(title: strings.visibility, icon: Icons.visibility_outlined),
            _VisibilityTile(
              label: strings.jobTitle,
              value: _draft.visibility.title,
              onChanged: (v) => setState(() => _draft = _draft.copyWith(
                  visibility: VisibilitySettings(
                      title: v,
                      company: _draft.visibility.company,
                      phones: _draft.visibility.phones,
                      emails: _draft.visibility.emails,
                      website: _draft.visibility.website,
                      address: _draft.visibility.address,
                      bio: _draft.visibility.bio,
                      photo: _draft.visibility.photo,
                      socialLinks: _draft.visibility.socialLinks))),
            ),
            ..._visibilityTiles(strings),
            const SizedBox(height: 8),
            Text(
              VCardBuilder.fitsOfflineQr(preview)
                  ? '✓ ${strings.offlineMode} QR available'
                  : '⚠ ${strings.offlineMode} QR too large — will use ${strings.onlineMode}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        icon: const Icon(Icons.check_rounded),
        label: Text(strings.save),
      ),
    );
  }

  /// Remaining visibility switches generated compactly.
  List<Widget> _visibilityTiles(AppStrings strings) {
    Widget tile(String label, bool value, bool Function(VisibilitySettings) get_,
            VisibilitySettings Function(VisibilitySettings, bool) set_) =>
        _VisibilityTile(
          label: label,
          value: value,
          onChanged: (v) => setState(() =>
              _draft = _draft.copyWith(visibility: set_(_draft.visibility, v))),
        );
    VisibilitySettings copy(VisibilitySettings s, {bool? t, bool? c, bool? p, bool? e, bool? w, bool? a, bool? b, bool? ph, bool? sl}) =>
        VisibilitySettings(
          title: t ?? s.title,
          company: c ?? s.company,
          phones: p ?? s.phones,
          emails: e ?? s.emails,
          website: w ?? s.website,
          address: a ?? s.address,
          bio: b ?? s.bio,
          photo: ph ?? s.photo,
          socialLinks: sl ?? s.socialLinks,
        );
    return [
      tile(strings.company, _draft.visibility.company, (s) => s.company, (s, v) => copy(s, c: v)),
      tile(strings.phone, _draft.visibility.phones, (s) => s.phones, (s, v) => copy(s, p: v)),
      tile(strings.emailAddress, _draft.visibility.emails, (s) => s.emails, (s, v) => copy(s, e: v)),
      tile(strings.website, _draft.visibility.website, (s) => s.website, (s, v) => copy(s, w: v)),
      tile(strings.address, _draft.visibility.address, (s) => s.address, (s, v) => copy(s, a: v)),
      tile(strings.bio, _draft.visibility.bio, (s) => s.bio, (s, v) => copy(s, b: v)),
      tile(strings.photo, _draft.visibility.photo, (s) => s.photo, (s, v) => copy(s, ph: v)),
      tile(strings.socialLinks, _draft.visibility.socialLinks, (s) => s.socialLinks,
          (s, v) => copy(s, sl: v)),
    ];
  }

  FormFieldValidator<String> _urlValidator(AppStrings strings) => (v) {
        if (v == null || v.trim().isEmpty) return null;
        final uri = Uri.tryParse(_normalizeUrl(v.trim()));
        return (uri != null && uri.hasScheme && uri.host.contains('.'))
            ? null
            : strings.validationUrl;
      };
}

class _SocialLinkDraft {
  _SocialLinkDraft({required this.type, required this.url});
  SocialLinkType type;
  final TextEditingController url;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _RepeatField extends StatelessWidget {
  const _RepeatField({
    required this.controller,
    required this.keyboardType,
    required this.hint,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final TextEditingController controller;
  final TextInputType keyboardType;
  final String hint;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(hintText: hint),
              onChanged: onChanged,
            ),
          ),
          if (canRemove)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
            ),
        ],
      ),
    );
  }
}

class _AddFieldLink extends StatelessWidget {
  const _AddFieldLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.add_rounded),
        label: Text(MaterialLocalizations.of(context).addButtonLabel),
      ),
    );
  }
}

class _VisibilityTile extends StatelessWidget {
  const _VisibilityTile({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value ? strings.visibleToOthers : strings.hidden),
      value: value,
      onChanged: onChanged,
    );
  }
}
