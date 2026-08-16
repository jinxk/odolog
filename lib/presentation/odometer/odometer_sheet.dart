import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failures.dart';
import '../../domain/calculators/latest_odometer.dart';
import '../../domain/entities/odometer_reading.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/usecases/get_vehicle_history.dart';
import '../common/csv_safe_text_formatter.dart';
import '../common/error_view.dart';
import '../common/formatting.dart';
import '../common/single_decimal_formatter.dart';
import '../providers/app_providers.dart';
import '../providers/auto_backup_provider.dart';
import '../providers/usecases.dart';

/// Opens the update odometer sheet and, when a reading is saved, confirms it
/// and refreshes everything that reads the vehicle's latest reading.
Future<void> showOdometerSheet(
  BuildContext context,
  WidgetRef ref,
  Vehicle vehicle,
) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => OdometerSheet(vehicle: vehicle),
  );
  if (saved != true) return;
  refreshOdometerReaders(ref, vehicle);
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Odometer updated')));
  }
  unawaited(ref.read(autoBackupProvider.notifier).runIfDue());
}

/// Invalidates every provider whose value moves when a reading is added or
/// removed: the readings list itself, the dashboard and stats figures, the
/// timeline, and the service countdown, which is measured in km.
void refreshOdometerReaders(WidgetRef ref, Vehicle vehicle) {
  ref.invalidate(odometerReadingsProvider(vehicle.id));
  ref.invalidate(vehicleStatsProvider(vehicle.id));
  ref.invalidate(historyProvider(vehicle.id));
  ref.invalidate(serviceDueProvider(vehicle));
}

/// A compact bottom sheet form: the reading, when it was taken, and an
/// optional note. Local state rather than a Riverpod form notifier, the same
/// as the log service sheet: there is no derived hint to keep in sync across
/// rebuilds.
class OdometerSheet extends ConsumerStatefulWidget {
  const OdometerSheet({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<OdometerSheet> createState() => _OdometerSheetState();
}

class _OdometerSheetState extends ConsumerState<OdometerSheet> {
  final _odometer = TextEditingController();
  final _note = TextEditingController();
  DateTime _recordedAt = DateTime.now();
  bool _saving = false;
  String? _odometerError;
  String? _dateError;
  String? _noteError;
  Failure? _failure;

  @override
  void dispose() {
    _odometer.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (!mounted) return;
    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _recordedAt.hour,
        time?.minute ?? _recordedAt.minute,
      );
      _dateError = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _odometerError = null;
      _dateError = null;
      _noteError = null;
      _failure = null;
    });
    final odometer = double.tryParse(_odometer.text.trim());
    if (odometer == null) {
      setState(() {
        _saving = false;
        _odometerError = 'Enter the odometer reading.';
      });
      return;
    }
    final note = _note.text.trim();
    final reading = OdometerReading(
      id: 0,
      vehicleId: widget.vehicle.id,
      odometer: odometer,
      recordedAt: _recordedAt,
      note: note.isEmpty ? null : note,
    );
    final result = await ref.read(logOdometerReadingProvider).execute(reading);
    if (!mounted) return;
    result.match(
      (failure) => setState(() {
        _saving = false;
        _apply(failure);
      }),
      (_) => Navigator.of(context).pop(true),
    );
  }

  void _apply(Failure failure) {
    if (failure is! ValidationFailure) {
      _failure = failure;
      return;
    }
    switch (failure.field) {
      case 'odometer':
        _odometerError = failure.reason;
      case 'recordedAt':
        _dateError = failure.reason;
      case 'note':
        _noteError = failure.reason;
      default:
        _failure = failure;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history =
        ref.watch(historyProvider(widget.vehicle.id)).value ??
        const <HistoryItem>[];
    final refuels = [for (final item in history) item.entry];
    final readings =
        ref.watch(odometerReadingsProvider(widget.vehicle.id)).value ??
        const <OdometerReading>[];
    final latest = LatestOdometerCalculator.of(refuels, readings);
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
            Text('Update odometer', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              key: const Key('odometerReadingField'),
              controller: _odometer,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [SingleDecimalFormatter()],
              decoration: InputDecoration(
                labelText: 'Odometer',
                suffixText: 'km',
                helperText: latest == null
                    ? null
                    : 'Last reading ${formatDistance(latest.odometer)}',
                errorText: _odometerError,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('Date'),
              subtitle: Text(formatDateTime(_recordedAt)),
              onTap: _pickDateTime,
            ),
            if (_dateError != null)
              Text(
                _dateError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('odometerNoteField'),
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [csvSafeTextFormatter],
              decoration: InputDecoration(
                labelText: 'Note',
                hintText: 'Optional',
                errorText: _noteError,
              ),
            ),
            if (_failure != null) ...[
              const SizedBox(height: 12),
              ErrorView(error: _failure!, compact: true, onRetry: _save),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('saveOdometerButton'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
