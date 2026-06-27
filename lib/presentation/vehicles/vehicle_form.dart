import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failures.dart';
import '../../domain/calculators/service_due_calculator.dart';
import '../../domain/entities/vehicle.dart';
import '../common/csv_safe_text_formatter.dart';
import '../common/formatting.dart';
import '../common/single_decimal_formatter.dart';
import '../providers/app_providers.dart';
import '../providers/auto_backup_provider.dart';
import '../providers/usecases.dart';

/// The add and edit vehicle form, shared by onboarding and vehicle management.
/// Name, type, and fuel category are required and always visible. Registration,
/// tank capacity, and the company claimed mileage are optional and sit under a
/// "more details" divider; the document expiry dates sit under their own
/// "Documents" divider, and the two service intervals under a "Service
/// intervals" divider, so the fast path to adding a vehicle stays short. The
/// tank capacity and claimed mileage units follow the chosen fuel category.
class VehicleForm extends ConsumerStatefulWidget {
  const VehicleForm({
    super.key,
    this.initial,
    required this.saveLabel,
    required this.onSaved,
  });

  final Vehicle? initial;
  final String saveLabel;
  final void Function(Vehicle saved) onSaved;

  @override
  ConsumerState<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends ConsumerState<VehicleForm> {
  late final TextEditingController _name;
  late final TextEditingController _registration;
  late final TextEditingController _tankCapacity;
  late final TextEditingController _claimedMileage;
  late final TextEditingController _engineOilInterval;
  late final TextEditingController _generalServiceInterval;
  late VehicleType _type;
  late FuelCategory _category;
  late final Map<VehicleDocument, DateTime?> _docDates;
  bool _showMore = false;
  bool _showDocuments = false;
  bool _showServiceIntervals = false;
  bool _saving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _registration = TextEditingController(text: initial?.registrationNo ?? '');
    _tankCapacity = TextEditingController(
      text: initial?.tankCapacity == null
          ? ''
          : formatQuantity(initial!.tankCapacity!),
    );
    _claimedMileage = TextEditingController(
      text: initial?.claimedMileage == null
          ? ''
          : formatMileage(initial!.claimedMileage!),
    );
    _engineOilInterval = TextEditingController(
      text: initial?.engineOilIntervalKm == null
          ? ''
          : formatQuantity(initial!.engineOilIntervalKm!),
    );
    _generalServiceInterval = TextEditingController(
      text: initial?.generalServiceIntervalDays?.toString() ?? '',
    );
    _type = initial?.type ?? VehicleType.car;
    _category = initial?.fuelCategory ?? FuelCategory.petrol;
    _docDates = {
      for (final document in VehicleDocument.values)
        document: initial?.expiryFor(document),
    };
    _showMore =
        (initial?.registrationNo != null) ||
        (initial?.tankCapacity != null) ||
        (initial?.claimedMileage != null);
    _showDocuments = _docDates.values.any((date) => date != null);
    _showServiceIntervals =
        (initial?.engineOilIntervalKm != null) ||
        (initial?.generalServiceIntervalDays != null);
  }

  @override
  void dispose() {
    _name.dispose();
    _registration.dispose();
    _tankCapacity.dispose();
    _claimedMileage.dispose();
    _engineOilInterval.dispose();
    _generalServiceInterval.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _nameError = null;
    });
    final vehicle = Vehicle(
      id: widget.initial?.id ?? 0,
      name: _name.text.trim(),
      type: _type,
      fuelCategory: _category,
      registrationNo: _registration.text.trim().isEmpty
          ? null
          : _registration.text.trim(),
      tankCapacity: double.tryParse(_tankCapacity.text.trim()),
      claimedMileage: double.tryParse(_claimedMileage.text.trim()),
      insuranceExpiry: _docDates[VehicleDocument.insurance],
      pucExpiry: _docDates[VehicleDocument.puc],
      rcExpiry: _docDates[VehicleDocument.rc],
      fitnessExpiry: _docDates[VehicleDocument.fitness],
      engineOilIntervalKm: double.tryParse(_engineOilInterval.text.trim()),
      generalServiceIntervalDays: int.tryParse(
        _generalServiceInterval.text.trim(),
      ),
    );

    final result = widget.initial == null
        ? await ref.read(addVehicleProvider).execute(vehicle)
        : await ref.read(editVehicleProvider).execute(vehicle);

    if (!mounted) return;
    result.match(
      (failure) {
        setState(() {
          _saving = false;
          if (failure is ValidationFailure && failure.field == 'name') {
            _nameError = failure.reason;
          }
        });
      },
      (saved) {
        ref.invalidate(vehicleListProvider);
        unawaited(ref.read(autoBackupProvider.notifier).runIfDue());
        setState(() => _saving = false);
        widget.onSaved(saved);
      },
    );
  }

  /// Opens a date picker for [document], seeded at its current value or today.
  /// The range reaches five years back so an already lapsed paper can be
  /// recorded, and thirty years forward for a long RC.
  Future<void> _pickDate(VehicleDocument document) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _docDates[document] ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 30),
    );
    if (picked == null) return;
    setState(() => _docDates[document] = picked);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [csvSafeTextFormatter],
          decoration: InputDecoration(
            labelText: 'Name',
            hintText: 'Activa, Swift',
            errorText: _nameError,
          ),
        ),
        const SizedBox(height: 20),
        Text('Type', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final type in VehicleType.values)
              ChoiceChip(
                label: Text(vehicleTypeLabel(type)),
                selected: _type == type,
                onSelected: (_) => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Fuel', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final category in FuelCategory.values)
              ChoiceChip(
                label: Text(fuelCategoryLabel(category)),
                selected: _category == category,
                onSelected: (_) => setState(() => _category = category),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionDivider(
          label: 'More details',
          expanded: _showMore,
          onToggle: () => setState(() => _showMore = !_showMore),
        ),
        if (_showMore) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _registration,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [csvSafeTextFormatter],
            decoration: const InputDecoration(
              labelText: 'Registration number',
              hintText: 'Optional',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _tankCapacity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [SingleDecimalFormatter()],
            decoration: InputDecoration(
              labelText: 'Tank capacity',
              hintText: 'Optional',
              suffixText: unitLabel(_category),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _claimedMileage,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [SingleDecimalFormatter()],
            decoration: InputDecoration(
              labelText: 'Company claimed mileage',
              hintText: 'Optional',
              suffixText: mileageUnit(_category),
            ),
          ),
        ],
        const SizedBox(height: 12),
        _SectionDivider(
          label: 'Documents',
          expanded: _showDocuments,
          onToggle: () => setState(() => _showDocuments = !_showDocuments),
        ),
        if (_showDocuments) ...[
          const SizedBox(height: 4),
          for (final document in VehicleDocument.values)
            _DocumentDateField(
              document: document,
              value: _docDates[document],
              quickSet: _quickSetFor(document),
              onPick: () => _pickDate(document),
              onQuickSet: () => setState(
                () => _docDates[document] = _quickSetFor(document)!.compute(),
              ),
              onClear: () => setState(() => _docDates[document] = null),
            ),
        ],
        const SizedBox(height: 12),
        _SectionDivider(
          label: 'Service intervals',
          expanded: _showServiceIntervals,
          onToggle: () =>
              setState(() => _showServiceIntervals = !_showServiceIntervals),
        ),
        if (_showServiceIntervals) ...[
          const SizedBox(height: 20),
          TextField(
            controller: _engineOilInterval,
            keyboardType: const TextInputType.numberWithOptions(),
            inputFormatters: [SingleDecimalFormatter()],
            decoration: InputDecoration(
              labelText: 'Engine oil interval',
              hintText:
                  'Default ${ServiceDueCalculator.defaultEngineOilIntervalKm.toStringAsFixed(0)}',
              suffixText: 'km',
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _generalServiceInterval,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'General service interval',
              hintText:
                  'Default ${ServiceDueCalculator.defaultGeneralServiceIntervalDays}',
              suffixText: 'days',
            ),
          ),
        ],
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }

  /// The quick-set helper for a document, or null when there is no sensible
  /// default interval. Insurance renews yearly and a PUC every six months in
  /// India; RC and fitness vary too much to guess, so they get a picker only.
  _QuickSet? _quickSetFor(VehicleDocument document) => switch (document) {
    VehicleDocument.insurance => _QuickSet(
      label: '+1 yr',
      compute: () {
        final now = DateTime.now();
        return DateTime(now.year + 1, now.month, now.day);
      },
    ),
    VehicleDocument.puc => _QuickSet(
      label: '+6 mo',
      compute: () {
        final now = DateTime.now();
        return DateTime(now.year, now.month + 6, now.day);
      },
    ),
    VehicleDocument.rc || VehicleDocument.fitness => null,
  };
}

/// A relative date the form can offer as a one-tap default, never auto-applied.
class _QuickSet {
  const _QuickSet({required this.label, required this.compute});

  final String label;
  final DateTime Function() compute;
}

/// One document's row in the Documents section: its label, the set date or a
/// "Not set" hint, an optional quick-set button, a picker, and a clear button
/// once a date exists.
class _DocumentDateField extends StatelessWidget {
  const _DocumentDateField({
    required this.document,
    required this.value,
    required this.quickSet,
    required this.onPick,
    required this.onQuickSet,
    required this.onClear,
  });

  final VehicleDocument document;
  final DateTime? value;
  final _QuickSet? quickSet;
  final VoidCallback onPick;
  final VoidCallback onQuickSet;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(documentLabel(document), style: theme.textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  value == null ? 'Not set' : formatDate(value!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: value == null ? 0.5 : 0.75,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (quickSet != null && value == null)
            TextButton(onPressed: onQuickSet, child: Text(quickSet!.label)),
          IconButton(
            tooltip: 'Pick a date',
            icon: const Icon(Icons.event_outlined),
            onPressed: onPick,
          ),
          if (value != null)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close),
              onPressed: onClear,
            ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({
    required this.label,
    required this.expanded,
    required this.onToggle,
  });

  final String label;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Expanded(child: Divider()),
            const SizedBox(width: 12),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            Icon(expanded ? Icons.expand_less : Icons.expand_more),
            const Expanded(child: Divider()),
          ],
        ),
      ),
    );
  }
}
