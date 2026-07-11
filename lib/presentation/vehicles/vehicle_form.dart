import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/failures.dart';
import '../../domain/entities/vehicle.dart';
import '../common/csv_safe_text_formatter.dart';
import '../common/formatting.dart';
import '../providers/app_providers.dart';
import '../providers/usecases.dart';

/// The add and edit vehicle form, shared by onboarding and vehicle management.
/// Name, type, and fuel category are required and always visible; registration
/// and tank capacity are optional and sit under a "more details" divider. The
/// tank capacity unit follows the chosen fuel category.
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
  late VehicleType _type;
  late FuelCategory _category;
  bool _showMore = false;
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
    _type = initial?.type ?? VehicleType.car;
    _category = initial?.fuelCategory ?? FuelCategory.petrol;
    _showMore =
        (initial?.registrationNo != null) || (initial?.tankCapacity != null);
  }

  @override
  void dispose() {
    _name.dispose();
    _registration.dispose();
    _tankCapacity.dispose();
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
        setState(() => _saving = false);
        widget.onSaved(saved);
      },
    );
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
        _MoreDetailsDivider(
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
            decoration: InputDecoration(
              labelText: 'Tank capacity',
              hintText: 'Optional',
              suffixText: unitLabel(_category),
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
}

class _MoreDetailsDivider extends StatelessWidget {
  const _MoreDetailsDivider({required this.expanded, required this.onToggle});

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
            Text('More details', style: Theme.of(context).textTheme.labelLarge),
            Icon(expanded ? Icons.expand_less : Icons.expand_more),
            const Expanded(child: Divider()),
          ],
        ),
      ),
    );
  }
}
