import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/spacing.dart';
import '../../core/failures.dart';
import '../../data/csv/data_bundle_csv_codec.dart';
import '../../domain/usecases/export_data.dart';
import '../common/grouped_list.dart';
import '../common/motion.dart';
import '../common/section_header.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';
import '../providers/usecases.dart';
import 'currency_catalog.dart';

/// Settings: appearance, currency, the vehicle list, the data tools (export,
/// import, a blank template to fill in externally), and an about section. The
/// fuel unit is not set here: it follows each vehicle's category automatically.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _sourceUrl = 'https://github.com/jinxk/odolog';
  static const _version = '0.1.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      body: SafeArea(
        child: settings.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (settings) => ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenH,
              vertical: 8,
            ),
            children: [
              const EntranceFade(child: _ScreenTitle('Settings')),
              const SizedBox(height: AppSpacing.betweenSections),
              const SectionHeader('Appearance'),
              _ThemeSection(mode: settings.themeMode),
              const SizedBox(height: AppSpacing.betweenSections),
              const SectionHeader('Currency'),
              GroupedList(
                rows: [_CurrencyRow(symbol: settings.currencySymbol)],
              ),
              const SizedBox(height: AppSpacing.betweenSections),
              const SectionHeader('Vehicles'),
              GroupedList(
                rows: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(Icons.directions_car_outlined),
                    title: const Text('Vehicles'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/vehicles'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.betweenSections),
              const SectionHeader('Maintenance'),
              GroupedList(
                rows: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(Icons.build_outlined),
                    title: const Text('Service log'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/service-log'),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: const Text('Expenses'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/expenses'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.betweenSections),
              const SectionHeader('Data'),
              const _DataSection(),
              const SizedBox(height: AppSpacing.betweenSections),
              const SectionHeader('About'),
              GroupedList(
                rows: const [
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    title: Text('OdoLog'),
                    subtitle: Text('Version $_version, MIT licence'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    title: Text('Source'),
                    subtitle: SelectableText(_sourceUrl),
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

/// The left aligned large title that anchors the screen.
class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
    );
  }
}

class _ThemeSection extends ConsumerWidget {
  const _ThemeSection({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RadioGroup<ThemeMode>(
      groupValue: mode,
      onChanged: (value) {
        if (value != null) {
          ref.read(settingsProvider.notifier).setThemeMode(value);
        }
      },
      child: GroupedList(
        rows: [
          for (final option in ThemeMode.values)
            RadioListTile<ThemeMode>(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              value: option,
              title: Text(_themeLabel(option)),
            ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

/// The currency row and the picker sheet it opens. The stored value is a bare
/// symbol, so a symbol that predates this picker (or one hand edited into
/// shared preferences) still displays as-is even when it matches nothing in
/// [currencyCatalog].
class _CurrencyRow extends ConsumerWidget {
  const _CurrencyRow({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = currencyCatalog.where((c) => c.symbol == symbol).firstOrNull;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.payments_outlined),
      title: const Text('Currency'),
      subtitle: Text(match == null ? symbol : '${match.name} ($symbol)'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _pickCurrency(context, ref),
    );
  }

  Future<void> _pickCurrency(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final option in currencyCatalog)
              ListTile(
                title: Text(option.name),
                subtitle: Text(option.code),
                trailing: symbol == option.symbol
                    ? const Icon(Icons.check)
                    : Text(option.symbol),
                onTap: () => Navigator.of(sheetContext).pop(option.symbol),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    await ref.read(settingsProvider.notifier).setCurrencySymbol(selected);
  }
}

/// Export, import, and the blank template. Export and the template both write
/// a CSV to a temporary file and hand it to the Android share sheet; import
/// reads a CSV picked from the file system. All three are disabled while one
/// is running so a second tap cannot race the first.
class _DataSection extends ConsumerStatefulWidget {
  const _DataSection();

  @override
  ConsumerState<_DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends ConsumerState<_DataSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return GroupedList(
      rows: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.file_upload_outlined),
          title: const Text('Export data'),
          subtitle: const Text('Save everything to one CSV file'),
          enabled: !_busy,
          onTap: _exportData,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('Import data'),
          subtitle: const Text('Load everything from a CSV file'),
          enabled: !_busy,
          onTap: _importData,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.description_outlined),
          title: const Text('Download template'),
          subtitle: const Text('Get a blank CSV with the right columns'),
          enabled: !_busy,
          onTap: _downloadTemplate,
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    setState(() => _busy = true);
    final result = await ref.read(exportDataProvider).execute();
    if (!mounted) return;
    await result.match(
      (failure) => _reportFailure('Could not export your data.', failure),
      (bundle) => _shareCsv(
        DataBundleCsvWriter.write(bundle),
        _timestampedName('odolog_backup'),
      ),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _downloadTemplate() async {
    setState(() => _busy = true);
    await _shareCsv(DataBundleCsvWriter.template(), 'odolog_template.csv');
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _importData() async {
    setState(() => _busy = true);
    final picked = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'CSV', extensions: ['csv']),
      ],
    );
    if (picked == null) {
      if (mounted) setState(() => _busy = false);
      return;
    }
    final content = await picked.readAsString();
    final parsed = DataBundleCsvReader.read(content);
    if (!mounted) return;
    await parsed.match(
      (failure) => _reportFailure('Could not read that file.', failure),
      (bundle) => _importBundle(bundle),
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _importBundle(DataBundle bundle) async {
    final result = await ref.read(importDataProvider).execute(bundle);
    if (!mounted) return;
    await result.match(
      (failure) => _reportFailure('Could not import your data.', failure),
      (_) async {
        ref.invalidate(vehicleListProvider);
        _showMessage(
          'Imported ${bundle.vehicles.length} vehicles, '
          '${bundle.entries.length} refuels, ${bundle.serviceLog.length} '
          'services, and ${bundle.expenses.length} expenses.',
        );
      },
    );
  }

  Future<void> _shareCsv(String content, String fileName) async {
    final file = File('${Directory.systemTemp.path}/$fileName');
    await file.writeAsString(content);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'OdoLog data'),
    );
  }

  String _timestampedName(String prefix) {
    final now = DateTime.now();
    final stamp =
        '${now.year}${_pad(now.month)}${_pad(now.day)}-'
        '${_pad(now.hour)}${_pad(now.minute)}';
    return '${prefix}_$stamp.csv';
  }

  String _pad(int value) => value.toString().padLeft(2, '0');

  Future<void> _reportFailure(String title, Failure failure) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(_message(failure)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _message(Failure failure) => switch (failure) {
    ValidationFailure(:final reason) => reason,
    NotFoundFailure(:final message) => message,
    DatabaseFailure(:final message) => message,
  };

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
