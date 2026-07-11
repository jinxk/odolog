import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/fuel_variant.dart';
import '../../domain/entities/refuel_entry.dart';
import '../../domain/entities/vehicle.dart';
import '../common/formatting.dart';
import '../providers/app_providers.dart';
import '../providers/refuel_form_provider.dart';
import '../providers/settings_provider.dart';

const _otherVariant = '__other__';

/// The speed first refuel form. Three large numeric fields come first in the
/// order they are read off the pump and dashboard: odometer, quantity, price. A
/// live price per unit hint sits under price. Everything else lives in a
/// collapsed optional section.
class AddRefuelScreen extends ConsumerStatefulWidget {
  const AddRefuelScreen({super.key, required this.vehicle, this.existing});

  final Vehicle vehicle;
  final RefuelEntry? existing;

  @override
  ConsumerState<AddRefuelScreen> createState() => _AddRefuelScreenState();
}

class _AddRefuelScreenState extends ConsumerState<AddRefuelScreen> {
  late final String _flowId;
  late final TextEditingController _odometer;
  late final TextEditingController _quantity;
  late final TextEditingController _price;
  late final TextEditingController _station;
  late final TextEditingController _notes;
  late final TextEditingController _variantOther;
  bool _expanded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _flowId = widget.existing == null
        ? 'add:${widget.vehicle.id}'
        : 'edit:${widget.existing!.id}';
    final existing = widget.existing;
    _odometer = TextEditingController(
      text: existing == null ? '' : _plainNumber(existing.odometer),
    );
    _quantity = TextEditingController(
      text: existing == null ? '' : _plainNumber(existing.quantity),
    );
    _price = TextEditingController(
      text: existing == null ? '' : _plainNumber(existing.pricePaid),
    );
    _station = TextEditingController(text: existing?.stationName ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _variantOther = TextEditingController(text: existing?.variantOther ?? '');
    // Seeding the form state modifies a provider, which is not allowed during a
    // widget life-cycle, so it runs once after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(refuelFormProvider(_flowId).notifier)
          .configure(vehicleId: widget.vehicle.id, existing: widget.existing);
    });
  }

  String _plainNumber(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  @override
  void dispose() {
    _odometer.dispose();
    _quantity.dispose();
    _price.dispose();
    _station.dispose();
    _notes.dispose();
    _variantOther.dispose();
    super.dispose();
  }

  RefuelForm get _controller => ref.read(refuelFormProvider(_flowId).notifier);

  Future<void> _save() async {
    setState(() => _saving = true);
    final saved = await _controller.submit();
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) return;
    ref.invalidate(vehicleStatsProvider(widget.vehicle.id));
    ref.invalidate(historyProvider(widget.vehicle.id));
    ref.invalidate(vehicleListProvider);
    ref.invalidate(refuelFormProvider(_flowId));
    if (context.mounted) context.pop(saved);
  }

  void _cancel() {
    ref.invalidate(refuelFormProvider(_flowId));
    if (context.canPop()) context.pop();
  }

  Future<void> _pickDateTime(DateTime current) async {
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    );
    _controller.setFilledAt(picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(refuelFormProvider(_flowId));
    final category = widget.vehicle.fuelCategory;
    final currency = ref.watch(settingsProvider).value?.currencySymbol ?? 'Rs';
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit refuel' : 'Add refuel'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancel),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _numberField(
            key: const Key('odometerField'),
            controller: _odometer,
            label: 'Odometer (km)',
            error: state.fieldErrors['odometer'],
            onChanged: _controller.setOdometer,
          ),
          if (state.showOverride)
            CheckboxListTile(
              key: const Key('overrideCheckbox'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: state.odometerOverride,
              onChanged: (value) => _controller.setOverride(value ?? false),
              title: const Text('Allow a lower odometer reading'),
              subtitle: const Text(
                'The affected mileage is flagged so the math stays honest.',
              ),
            ),
          const SizedBox(height: 20),
          _numberField(
            key: const Key('quantityField'),
            controller: _quantity,
            label: 'Quantity (${unitLabel(category)})',
            error: state.fieldErrors['quantity'],
            onChanged: _controller.setQuantity,
          ),
          const SizedBox(height: 20),
          _numberField(
            key: const Key('priceField'),
            controller: _price,
            label: 'Price paid ($currency)',
            error: state.fieldErrors['price'],
            onChanged: _controller.setPrice,
          ),
          const SizedBox(height: 6),
          _PriceHint(
            pricePerUnit: state.pricePerUnit,
            currency: currency,
            category: category,
          ),
          const SizedBox(height: 12),
          _OptionalDivider(
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded) _optionalSection(context, state, category, currency),
          if (state.fieldErrors['date'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                state.fieldErrors['date']!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(isEdit ? 'Save changes' : 'Save refuel'),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String? error,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      decoration: InputDecoration(labelText: label, errorText: error),
      onChanged: onChanged,
    );
  }

  Widget _optionalSection(
    BuildContext context,
    RefuelFormState state,
    FuelCategory category,
    String currency,
  ) {
    final catalog = ref.watch(catalogProvider(category));
    final filledAt = state.filledAt ?? DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        catalog.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (variants) => _variantField(state, variants),
        ),
        if (state.variantId == _otherVariant) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _variantOther,
            decoration: const InputDecoration(labelText: 'Fuel name'),
            onChanged: (value) => _controller.setVariant(
              variantId: _otherVariant,
              variantOther: value,
            ),
          ),
        ],
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event),
          title: const Text('Date and time'),
          subtitle: Text(formatDateTime(filledAt)),
          onTap: () => _pickDateTime(filledAt),
        ),
        SwitchListTile(
          key: const Key('fullTankToggle'),
          contentPadding: EdgeInsets.zero,
          value: state.fullTank,
          onChanged: _controller.setFullTank,
          title: const Text('Full tank'),
          subtitle: const Text('Only full to full fills produce mileage.'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _station,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Station'),
          onChanged: _controller.setStation,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _notes,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Notes'),
          onChanged: _controller.setNotes,
        ),
      ],
    );
  }

  Widget _variantField(RefuelFormState state, List<FuelVariant> variants) {
    return DropdownButtonFormField<String?>(
      initialValue: state.variantId,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Fuel variant'),
      items: [
        const DropdownMenuItem<String?>(child: Text('None')),
        for (final variant in variants)
          DropdownMenuItem<String?>(
            value: variant.id,
            child: Text('${variant.brandName} ${variant.name}'),
          ),
        const DropdownMenuItem<String?>(
          value: _otherVariant,
          child: Text('Other'),
        ),
      ],
      onChanged: (value) {
        if (value == _otherVariant) {
          _controller.setVariant(
            variantId: _otherVariant,
            variantOther: _variantOther.text,
          );
        } else {
          _controller.setVariant(variantId: value, variantOther: null);
        }
      },
    );
  }
}

class _PriceHint extends StatelessWidget {
  const _PriceHint({
    required this.pricePerUnit,
    required this.currency,
    required this.category,
  });

  final double? pricePerUnit;
  final String currency;
  final FuelCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (pricePerUnit == null) {
      return Text(
        'Price per unit shows here as you type.',
        style: theme.textTheme.bodySmall,
      );
    }
    return Text(
      '$currency ${pricePerUnit!.toStringAsFixed(2)} ${perUnitLabel(category)}',
      key: const Key('priceHint'),
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.secondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _OptionalDivider extends StatelessWidget {
  const _OptionalDivider({required this.expanded, required this.onToggle});

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
            Text(
              'Optional details',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Icon(expanded ? Icons.expand_less : Icons.expand_more),
            const Expanded(child: Divider()),
          ],
        ),
      ),
    );
  }
}
