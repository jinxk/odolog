import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/shapes.dart';
import '../../domain/entities/fuel_variant.dart';
import '../../domain/entities/refuel_entry.dart';
import '../../domain/entities/vehicle.dart';
import '../common/csv_safe_text_formatter.dart';
import '../common/formatting.dart';
import '../common/grouped_list.dart';
import '../common/single_decimal_formatter.dart';
import '../providers/app_providers.dart';
import '../providers/refuel_form_provider.dart';
import '../providers/settings_provider.dart';

const _otherVariant = '__other__';
const _noneVariant = '__none__';

/// The speed first refuel form. Three large numeric fields come first in the
/// order they are read off the pump and dashboard: odometer, quantity, price. A
/// live price per unit hint sits under price. The full tank choice sits in the
/// same always visible fast path, since a partial fill mislabeled as full
/// silently corrupts the mileage window the rest of the app is built on.
/// Everything else lives in a collapsed optional section, and Save is pinned
/// to the bottom bar so it never scrolls out of the thumb zone.
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
    // A haptic confirms the write even when the rider cannot read fine print
    // in glare. It is fire and forget: the pop must not wait on it, and the
    // destination screen shows a snack bar once the pop itself resolves.
    unawaited(HapticFeedback.mediumImpact());
    context.pop(saved);
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

    // The last odometer reading removes the single largest source of at-pump
    // typing, but only as a hint: silently pre-filling the value is not
    // approved, and an edit already carries its own reading.
    String? odometerHint;
    if (!isEdit) {
      final items = ref.watch(historyProvider(widget.vehicle.id)).value;
      if (items != null && items.isNotEmpty) {
        odometerHint = 'Last: ${formatDistance(items.last.entry.odometer)}';
      }
    }

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
            label: 'Odometer',
            unit: 'km',
            autofocus: true,
            textInputAction: TextInputAction.next,
            helperText: odometerHint,
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
          _FullTankControl(
            fullTank: state.fullTank,
            onChanged: _controller.setFullTank,
          ),
          const SizedBox(height: 20),
          _numberField(
            key: const Key('quantityField'),
            controller: _quantity,
            label: 'Quantity',
            unit: unitLabel(category),
            textInputAction: TextInputAction.next,
            error: state.fieldErrors['quantity'],
            onChanged: _controller.setQuantity,
          ),
          const SizedBox(height: 20),
          _numberField(
            key: const Key('priceField'),
            controller: _price,
            label: 'Price paid',
            unit: currency,
            textInputAction: TextInputAction.done,
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
          if (_expanded) _optionalSection(context, state, category),
          if (state.fieldErrors['date'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                state.fieldErrors['date']!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 64,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(isEdit ? 'Save changes' : 'Save refuel'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String unit,
    required String? error,
    required ValueChanged<String> onChanged,
    String? helperText,
    bool autofocus = false,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      key: key,
      controller: controller,
      autofocus: autofocus,
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [SingleDecimalFormatter()],
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        helperText: helperText,
        errorText: error,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        // A filled field with an OutlineInputBorder puts the floating label on
        // the border line itself, which straddles the fill and the page
        // background around it. An UnderlineInputBorder never notches, so the
        // label stays inside the fill and only the bottom indicator (grey at
        // rest, amber on focus) shows the field's state.
        border: UnderlineInputBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppShapes.inputRadius),
          ),
        ),
      ),
      onChanged: onChanged,
    );
  }

  Widget _optionalSection(
    BuildContext context,
    RefuelFormState state,
    FuelCategory category,
  ) {
    final catalog = ref.watch(catalogProvider(category));
    final filledAt = state.filledAt ?? DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GroupedList(
        rows: [
          catalog.when(
            loading: () => const ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(Icons.local_gas_station_outlined),
              title: Text('Fuel variant'),
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (variants) => _variantRow(state, variants),
          ),
          if (state.variantId == _otherVariant) _variantOtherRow(),
          _dateRow(filledAt),
          _textRow(
            controller: _station,
            label: 'Station',
            capitalization: TextCapitalization.words,
            onChanged: _controller.setStation,
          ),
          _textRow(
            controller: _notes,
            label: 'Notes',
            capitalization: TextCapitalization.sentences,
            onChanged: _controller.setNotes,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _variantRow(RefuelFormState state, List<FuelVariant> variants) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.local_gas_station_outlined),
      title: const Text('Fuel variant'),
      subtitle: Text(_variantLabel(state, variants)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _pickVariant(variants, state),
    );
  }

  String _variantLabel(RefuelFormState state, List<FuelVariant> variants) {
    if (state.variantId == _otherVariant) {
      final custom = state.variantOther;
      return custom != null && custom.isNotEmpty ? custom : 'Other';
    }
    if (state.variantId == null) return 'None';
    for (final variant in variants) {
      if (variant.id == state.variantId) {
        return '${variant.brandName} ${variant.name}';
      }
    }
    return 'None';
  }

  /// Opens a bottom sheet picker for the fuel variant, consistent with the
  /// vehicle switcher sheet on the dashboard, in place of a raw dropdown.
  Future<void> _pickVariant(
    List<FuelVariant> variants,
    RefuelFormState state,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('None'),
              trailing: state.variantId == null
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(_noneVariant),
            ),
            for (final variant in variants)
              ListTile(
                title: Text('${variant.brandName} ${variant.name}'),
                trailing: state.variantId == variant.id
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(variant.id),
              ),
            ListTile(
              title: const Text('Other'),
              trailing: state.variantId == _otherVariant
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.of(sheetContext).pop(_otherVariant),
            ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    if (selected == _noneVariant) {
      _controller.setVariant(variantId: null, variantOther: null);
    } else if (selected == _otherVariant) {
      _controller.setVariant(
        variantId: _otherVariant,
        variantOther: _variantOther.text,
      );
    } else {
      _controller.setVariant(variantId: selected, variantOther: null);
    }
  }

  Widget _variantOtherRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: _variantOther,
        decoration: const InputDecoration(
          labelText: 'Fuel name',
          border: InputBorder.none,
        ),
        onChanged: (value) => _controller.setVariant(
          variantId: _otherVariant,
          variantOther: value,
        ),
      ),
    );
  }

  Widget _dateRow(DateTime filledAt) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const Icon(Icons.event_outlined),
      title: const Text('Date and time'),
      subtitle: Text(formatDateTime(filledAt)),
      onTap: () => _pickDateTime(filledAt),
    );
  }

  Widget _textRow({
    required TextEditingController controller,
    required String label,
    required TextCapitalization capitalization,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: TextField(
        controller: controller,
        textCapitalization: capitalization,
        maxLines: maxLines,
        inputFormatters: [csvSafeTextFormatter],
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        onChanged: onChanged,
      ),
    );
  }
}

/// The full tank versus part fill choice, promoted out of the collapsed
/// optional section into the always visible fast path. A partial fill
/// mislabeled as full silently corrupts the mileage window, so the correction
/// is a one tap, always visible action rather than something buried behind an
/// expander.
class _FullTankControl extends StatelessWidget {
  const _FullTankControl({required this.fullTank, required this.onChanged});

  final bool fullTank;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<bool>(
            key: const Key('fullTankToggle'),
            segments: const [
              ButtonSegment(value: true, label: Text('Full tank')),
              ButtonSegment(value: false, label: Text('Part fill')),
            ],
            selected: {fullTank},
            showSelectedIcon: false,
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ),
      ],
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
