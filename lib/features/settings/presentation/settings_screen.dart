import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/theme/app_theme.dart';

/// User preferences: language (English / বাংলা), theme mode
/// (system / light / dark) and app accent color. All choices are persisted
/// locally via SharedPreferences, so they also work for offline users.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppStrings.of(context);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accentIndex = ref.watch(accentIndexProvider);

    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Language ----
          _SectionHeader(icon: Icons.translate_rounded, title: strings.language),
          Card(
            child: Column(
              children: [
                _RadioRow<String>(
                  value: 'system',
                  group: locale?.languageCode ?? 'system',
                  label: strings.systemMode,
                  onChanged: (v) =>
                      ref.read(localeProvider.notifier).setLanguage(v),
                ),
                for (final entry in AppStrings.languageNames.entries)
                  _RadioRow<String>(
                    value: entry.key,
                    group: locale?.languageCode ?? 'system',
                    label: entry.value,
                    onChanged: (v) =>
                        ref.read(localeProvider.notifier).setLanguage(v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Appearance ----
          _SectionHeader(
              icon: Icons.dark_mode_rounded, title: strings.appearance),
          Card(
            child: Column(
              children: [
                _RadioRow<ThemeMode>(
                  value: ThemeMode.system,
                  group: themeMode,
                  label: strings.systemMode,
                  icon: Icons.brightness_auto_rounded,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).set(v),
                ),
                _RadioRow<ThemeMode>(
                  value: ThemeMode.light,
                  group: themeMode,
                  label: strings.lightMode,
                  icon: Icons.wb_sunny_rounded,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).set(v),
                ),
                _RadioRow<ThemeMode>(
                  value: ThemeMode.dark,
                  group: themeMode,
                  label: strings.darkMode,
                  icon: Icons.nightlight_round,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).set(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ---- Accent color ----
          _SectionHeader(
              icon: Icons.palette_rounded, title: strings.accentColor),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var i = 0; i < AppColors.cardAccents.length; i++)
                    _AccentSwatch(
                      color: AppColors.cardAccents[i],
                      selected: i == accentIndex,
                      onTap: () =>
                          ref.read(accentIndexProvider.notifier).set(i),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _RadioRow<T> extends StatelessWidget {
  const _RadioRow({
    required this.value,
    required this.group,
    required this.label,
    required this.onChanged,
    this.icon,
  });

  final T value;
  final T group;
  final String label;
  final ValueChanged<T> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // Whole row is a large tap target (a11y).
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            Radio<T>(
              groupValue: group,
              value: value,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$color',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}
