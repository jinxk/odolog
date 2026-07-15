import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/failures.dart';
import '../../domain/calculators/mileage_calculator.dart';
import '../../domain/entities/refuel_entry.dart';
import 'auto_backup_provider.dart';
import 'usecases.dart';

part 'refuel_form_provider.g.dart';

/// The in progress state of an add or edit refuel form. Numbers are held as the
/// raw field text so the live price per unit hint can recompute on every
/// keystroke, and field errors are keyed by the same field names the use cases
/// report, so a failure renders against the right input.
class RefuelFormState {
  const RefuelFormState({
    this.vehicleId = 0,
    this.editingEntryId,
    this.odometer = '',
    this.quantity = '',
    this.price = '',
    this.variantId,
    this.variantOther,
    this.filledAt,
    this.fullTank = true,
    this.station = '',
    this.notes = '',
    this.odometerOverride = false,
    this.showOverride = false,
    this.fieldErrors = const {},
    this.lastPricePerUnit,
    this.quantityTouched = false,
  });

  final int vehicleId;
  final int? editingEntryId;
  final String odometer;
  final String quantity;
  final String price;
  final String? variantId;
  final String? variantOther;
  final DateTime? filledAt;
  final bool fullTank;
  final String station;
  final String notes;
  final bool odometerOverride;

  /// Turns true only after an odometer ordering failure, so the override
  /// checkbox appears inline exactly when that specific problem occurs.
  final bool showOverride;
  final Map<String, String> fieldErrors;

  /// This vehicle's last known price per unit, seeded from its most recent
  /// refuel. Backs the amount to quantity derivation and the "Last price" hint.
  /// Null when the vehicle has no prior fill to read a price from.
  final double? lastPricePerUnit;

  /// Turns true once the user types in the quantity field, which stops the
  /// amount to quantity derivation for the rest of the flow. An edit seeds it
  /// true so an existing quantity is never derived over.
  final bool quantityTouched;

  bool get isEditing => editingEntryId != null;

  /// The derived price per unit for the hint, or null until both fields parse
  /// to positive numbers.
  double? get pricePerUnit {
    final q = double.tryParse(quantity);
    final p = double.tryParse(price);
    if (q == null || p == null || q <= 0 || p <= 0) return null;
    return p / q;
  }

  RefuelFormState copyWith({
    int? vehicleId,
    int? editingEntryId,
    String? odometer,
    String? quantity,
    String? price,
    Object? variantId = _sentinel,
    Object? variantOther = _sentinel,
    DateTime? filledAt,
    bool? fullTank,
    String? station,
    String? notes,
    bool? odometerOverride,
    bool? showOverride,
    Map<String, String>? fieldErrors,
    double? lastPricePerUnit,
    bool? quantityTouched,
  }) {
    return RefuelFormState(
      vehicleId: vehicleId ?? this.vehicleId,
      editingEntryId: editingEntryId ?? this.editingEntryId,
      odometer: odometer ?? this.odometer,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      variantId: variantId == _sentinel ? this.variantId : variantId as String?,
      variantOther: variantOther == _sentinel
          ? this.variantOther
          : variantOther as String?,
      filledAt: filledAt ?? this.filledAt,
      fullTank: fullTank ?? this.fullTank,
      station: station ?? this.station,
      notes: notes ?? this.notes,
      odometerOverride: odometerOverride ?? this.odometerOverride,
      showOverride: showOverride ?? this.showOverride,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      lastPricePerUnit: lastPricePerUnit ?? this.lastPricePerUnit,
      quantityTouched: quantityTouched ?? this.quantityTouched,
    );
  }
}

const _sentinel = Object();

/// Keeps a refuel form's state alive for the duration of one add or edit flow,
/// keyed by a flow id so add and edit never share a buffer. Disposed explicitly
/// with ref.invalidate on save or cancel. A brief navigation away and back
/// therefore does not wipe half typed input.
@Riverpod(keepAlive: true)
class RefuelForm extends _$RefuelForm {
  @override
  RefuelFormState build(String flowId) => const RefuelFormState();

  /// Seeds the form once when the screen opens. For an edit, pass the existing
  /// entry so its values populate the fields. Then reads the vehicle's last
  /// known price per unit in the background, which backs the amount to quantity
  /// derivation and the "Last price" hint.
  Future<void> configure({
    required int vehicleId,
    RefuelEntry? existing,
  }) async {
    if (state.vehicleId != 0 || state.editingEntryId != null) return;
    if (existing == null) {
      state = state.copyWith(vehicleId: vehicleId, filledAt: DateTime.now());
    } else {
      state = RefuelFormState(
        vehicleId: vehicleId,
        editingEntryId: existing.id,
        odometer: _trimZero(existing.odometer),
        quantity: _trimZero(existing.quantity),
        price: _trimZero(existing.pricePaid),
        variantId: existing.variantId,
        variantOther: existing.variantOther,
        filledAt: existing.filledAt,
        fullTank: existing.fullTank,
        station: existing.stationName ?? '',
        notes: existing.notes ?? '',
        odometerOverride: existing.odometerOverride,
        quantityTouched: true,
      );
    }
    final history = await ref
        .read(getVehicleHistoryProvider)
        .execute(vehicleId);
    final lastPrice = history.match(
      (_) => null,
      (items) => const MileageCalculator().lastKnownPricePerUnit([
        for (final item in items) item.entry,
      ]),
    );
    if (lastPrice != null) {
      state = state.copyWith(lastPricePerUnit: lastPrice);
    }
  }

  void setOdometer(String value) => state = state.copyWith(
    odometer: value,
    fieldErrors: _without('odometer'),
  );

  /// A quantity edit is always the user's own: it marks the field touched so the
  /// amount to quantity derivation stops for the rest of the flow.
  void setQuantity(String value) => state = state.copyWith(
    quantity: value,
    quantityTouched: true,
    fieldErrors: _without('quantity'),
  );

  /// Sets the amount paid and, while the quantity field is still untouched and
  /// a last price is known, refills the derived quantity live off it.
  void setPrice(String value) => state = state.copyWith(
    price: value,
    quantity: _derivedQuantity(value),
    fieldErrors: _without('price'),
  );

  /// The quantity to show for [price]: the derived litres while derivation is
  /// live, cleared when the amount is empty or invalid, or the current value
  /// left as is once the user has taken over the quantity field or no last
  /// price exists to derive from.
  String _derivedQuantity(String price) {
    if (state.quantityTouched) return state.quantity;
    final lastPrice = state.lastPricePerUnit;
    if (lastPrice == null) return state.quantity;
    final amount = double.tryParse(price);
    if (amount == null || amount <= 0) return '';
    return (amount / lastPrice).toStringAsFixed(2);
  }

  void setStation(String value) => state = state.copyWith(station: value);
  void setNotes(String value) => state = state.copyWith(notes: value);
  void setFilledAt(DateTime value) => state = state.copyWith(filledAt: value);
  void setFullTank(bool value) => state = state.copyWith(fullTank: value);
  void setOverride(bool value) =>
      state = state.copyWith(odometerOverride: value);

  void setVariant({String? variantId, String? variantOther}) =>
      state = state.copyWith(variantId: variantId, variantOther: variantOther);

  Map<String, String> _without(String field) {
    if (!state.fieldErrors.containsKey(field)) return state.fieldErrors;
    return {
      for (final entry in state.fieldErrors.entries)
        if (entry.key != field) entry.key: entry.value,
    };
  }

  /// Validates and writes the entry. Returns the saved entry on success, or null
  /// after mapping a validation failure onto the offending field.
  Future<RefuelEntry?> submit() async {
    final odometer = double.tryParse(state.odometer);
    if (odometer == null) {
      state = state.copyWith(
        fieldErrors: {'odometer': 'Enter the odometer reading.'},
      );
      return null;
    }
    final quantity = double.tryParse(state.quantity) ?? 0;
    final price = double.tryParse(state.price) ?? 0;

    final entry = RefuelEntry(
      id: state.editingEntryId ?? 0,
      vehicleId: state.vehicleId,
      filledAt: state.filledAt ?? DateTime.now(),
      odometer: odometer,
      quantity: quantity,
      pricePaid: price,
      fullTank: state.fullTank,
      variantId: state.variantId,
      variantOther: state.variantOther,
      stationName: state.station.trim().isEmpty ? null : state.station.trim(),
      notes: state.notes.trim().isEmpty ? null : state.notes.trim(),
      odometerOverride: state.odometerOverride,
    );

    final result = state.isEditing
        ? await ref.read(editRefuelProvider).execute(entry)
        : await ref.read(logRefuelProvider).execute(entry);

    return result.match(
      (failure) {
        _applyFailure(failure);
        return null;
      },
      (saved) {
        unawaited(ref.read(autoBackupProvider.notifier).runIfDue());
        return saved;
      },
    );
  }

  void _applyFailure(Failure failure) {
    if (failure is ValidationFailure) {
      final field = _fieldFor(failure.field);
      // The refuel use cases only fail on the odometer field for an ordering
      // problem, in either direction, so the field alone identifies it.
      final isOdometerOrder = field == 'odometer';
      state = state.copyWith(
        fieldErrors: {field: failure.reason},
        showOverride: isOdometerOrder ? true : null,
      );
    } else if (failure is NotFoundFailure) {
      state = state.copyWith(fieldErrors: {'form': failure.message});
    } else if (failure is DatabaseFailure) {
      state = state.copyWith(
        fieldErrors: {'form': 'Could not save. Try again.'},
      );
    }
  }

  String _fieldFor(String field) => field == 'filledAt' ? 'date' : field;

  String _trimZero(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }
}
