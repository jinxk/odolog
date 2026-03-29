import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/section_header.dart';
import '../providers/settings_provider.dart';

/// Settings: theme mode, currency symbol, the data tools that arrive in v0.2,
/// and an about section. The fuel unit is not set here: it follows each
/// vehicle's category automatically.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _sourceUrl = 'https://github.com/jinxk/odolog';
  static const _version = '0.1.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SectionHeader('Theme'),
            RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(value);
                }
              },
              child: Column(
                children: [
                  for (final mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      contentPadding: EdgeInsets.zero,
                      value: mode,
                      title: Text(_themeLabel(mode)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const SectionHeader('Currency'),
            _CurrencyField(symbol: settings.currencySymbol),
            const SizedBox(height: 8),
            const SectionHeader('Data'),
            _PlannedTile(
              icon: Icons.file_download_outlined,
              title: 'Export CSV',
            ),
            _PlannedTile(icon: Icons.file_upload_outlined, title: 'Import CSV'),
            _PlannedTile(
              icon: Icons.backup_outlined,
              title: 'Backup and restore',
            ),
            const SizedBox(height: 8),
            const SectionHeader('About'),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('OdoLog'),
              subtitle: Text('Version $_version, MIT licence'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Source'),
              subtitle: SelectableText(_sourceUrl),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

class _CurrencyField extends ConsumerStatefulWidget {
  const _CurrencyField({required this.symbol});

  final String symbol;

  @override
  ConsumerState<_CurrencyField> createState() => _CurrencyFieldState();
}

class _CurrencyFieldState extends ConsumerState<_CurrencyField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.symbol);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Currency symbol',
              hintText: 'Rs',
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: () => ref
              .read(settingsProvider.notifier)
              .setCurrencySymbol(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PlannedTile extends StatelessWidget {
  const _PlannedTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: false,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Text('Planned for v0.2'),
    );
  }
}
