import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/spacing.dart';
import '../../core/failures.dart';
import '../../domain/entities/service_log_entry.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/value_objects/service_due_status.dart';
import '../common/csv_safe_text_formatter.dart';
import '../common/empty_state.dart';
import '../common/formatting.dart';
import '../common/grouped_list.dart';
import '../common/section_header.dart';
import '../common/single_decimal_formatter.dart';
import '../common/stat_card.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';
import '../providers/usecases.dart';

/// The active vehicle's maintenance: a due countdown for each template up
/// top, then its service history, most recent first. Logging a service resets
/// that template's countdown and replans its reminder immediately, since
/// logging a service does not otherwise touch the vehicle list the app
/// listens on for a reschedule.
class ServiceLogScreen extends ConsumerWidget {
  const ServiceLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(currentVehicleProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Service log')),
      body: vehicle == null
          ? const EmptyState(
              icon: Icons.build_outlined,
              title: 'No vehicle yet',
              message: 'Add a vehicle to track its service log.',
            )
          : _ServiceLogBody(vehicle: vehicle),
      floatingActionButton: vehicle == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _logService(context, ref, vehicle),
              icon: const Icon(Icons.add),
              label: const Text('Log service'),
            ),
    );
  }

  Future<void> _logService(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LogServiceSheet(vehicle: vehicle),
    );
    if (saved != true) return;
    ref.invalidate(serviceLogProvider(vehicle.id));
    ref.invalidate(serviceDueProvider(vehicle));
    ref.invalidate(vehicleStatsProvider(vehicle.id));
    // Logging a service does not change the vehicle list, so the reminder
    // sync that listens for that has nothing to react to; replan explicitly.
    final vehicles = ref.read(vehicleListProvider).value;
    if (vehicles != null) {
      await ref.read(syncServiceRemindersProvider).execute(vehicles);
    }
  }
}

class _ServiceLogBody extends ConsumerWidget {
  const _ServiceLogBody({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final due = ref.watch(serviceDueProvider(vehicle));
    final log = ref.watch(serviceLogProvider(vehicle.id));
    return ListView(
      padding: const EdgeInsets.only(
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        top: 8,
        bottom: 88,
      ),
      children: [
        const SectionHeader('Due'),
        due.when(
          loading: () => const SectionCard(child: Text('Loading...')),
          error: (error, _) => SectionCard(child: Text('$error')),
          data: (statuses) => _DueCard(statuses: statuses),
        ),
        const SectionHeader('History'),
        log.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('$error'),
          data: (entries) => entries.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No services logged yet.'),
                )
              : GroupedList(
                  rows: [
                    for (final entry in entries)
                      _ServiceLogRow(vehicle: vehicle, entry: entry),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({required this.statuses});

  final List<ServiceDueStatus> statuses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < statuses.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  statuses[i].overdue
                      ? Icons.warning_amber_rounded
                      : Icons.build_outlined,
                  size: 18,
                  color: statuses[i].overdue
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    serviceDueSummary(statuses[i]),
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceLogRow extends ConsumerWidget {
  const _ServiceLogRow({required this.vehicle, required this.entry});

  final Vehicle vehicle;
  final ServiceLogEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(settingsProvider).value?.currencySymbol ?? 'Rs';
    final subtitleParts = <String>[
      formatDistance(entry.odometer),
      if (entry.cost != null) formatMoney(entry.cost!, currency),
    ];
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.build_outlined),
      title: Text(serviceTemplateLabel(entry.template)),
      subtitle: Text(
        '${formatDate(entry.performedAt)}, ${subtitleParts.join(', ')}'
        '${entry.note != null ? '\n${entry.note}' : ''}',
      ),
      isThreeLine: entry.note != null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmDelete(context, ref),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this service?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deleteServiceProvider).execute(entry.id);
    ref.invalidate(serviceLogProvider(vehicle.id));
    ref.invalidate(serviceDueProvider(vehicle));
    ref.invalidate(vehicleStatsProvider(vehicle.id));
  }
}

/// A compact bottom sheet form: which template, date, odometer, an optional
/// cost, and an optional note. Kept as plain local state rather than a
/// Riverpod form notifier since there is no live derived hint to keep in sync
/// across rebuilds, unlike the refuel form's price per unit.
class _LogServiceSheet extends ConsumerStatefulWidget {
  const _LogServiceSheet({required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<_LogServiceSheet> createState() => _LogServiceSheetState();
}

class _LogServiceSheetState extends ConsumerState<_LogServiceSheet> {
  ServiceTemplate _template = ServiceTemplate.engineOil;
  DateTime _performedAt = DateTime.now();
  final _odometer = TextEditingController();
  final _cost = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _odometer.dispose();
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _performedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _performedAt = picked);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final odometer = double.tryParse(_odometer.text.trim());
    if (odometer == null) {
      setState(() {
        _saving = false;
        _error = 'Enter the odometer reading.';
      });
      return;
    }
    final entry = ServiceLogEntry(
      id: 0,
      vehicleId: widget.vehicle.id,
      template: _template,
      performedAt: _performedAt,
      odometer: odometer,
      cost: double.tryParse(_cost.text.trim()),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    final result = await ref.read(logServiceProvider).execute(entry);
    if (!mounted) return;
    result.match(
      (failure) => setState(() {
        _saving = false;
        _error = _message(failure);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  String _message(Failure failure) => switch (failure) {
    ValidationFailure(:final reason) => reason,
    NotFoundFailure(:final message) => message,
    DatabaseFailure(:final message) => message,
  };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log service', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final template in ServiceTemplate.values)
                  ChoiceChip(
                    label: Text(serviceTemplateLabel(template)),
                    selected: _template == template,
                    onSelected: (_) => setState(() => _template = template),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Date'),
              subtitle: Text(formatDate(_performedAt)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('serviceOdometerField'),
              controller: _odometer,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [SingleDecimalFormatter()],
              decoration: InputDecoration(
                labelText: 'Odometer',
                suffixText: 'km',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('serviceCostField'),
              controller: _cost,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [SingleDecimalFormatter()],
              decoration: const InputDecoration(
                labelText: 'Cost',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('serviceNoteField'),
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [csvSafeTextFormatter],
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('saveServiceButton'),
                onPressed: _saving ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
