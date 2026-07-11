import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/failures.dart';
import '../../domain/entities/refuel_entry.dart';
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

  /// Turns true only after a non increasing odometer failure, so the override
  /// checkbox appears inline exactly when that specific problem occurs.
  final bool showOverride;
  final Map<String, String> fieldErrors;

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
  /// entry so its values populate the fields.
  void configure({required int vehicleId, RefuelEntry? existing}) {
    if (state.vehicleId != 0 || state.editingEntryId != null) return;
    if (existing == null) {
      state = state.copyWith(vehicleId: vehicleId, filledAt: DateTime.now());
      return;
    }
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
    );
  }

  void setOdometer(String value) => state = state.copyWith(
    odometer: value,
    fieldErrors: _without('odometer'),
  );
  void setQuantity(String value) => state = state.copyWith(
    quantity: value,
    fieldErrors: _without('quantity'),
  );
  void setPrice(String value) =>
      state = state.copyWith(price: value, fieldErrors: _without('price'));
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

    return result.match((failure) {
      _applyFailure(failure);
      return null;
    }, (saved) => saved);
  }

  void _applyFailure(Failure failure) {
    if (failure is ValidationFailure) {
      final field = _fieldFor(failure.field);
      final isOdometerOrder =
          field == 'odometer' && failure.reason.contains('previous');
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
