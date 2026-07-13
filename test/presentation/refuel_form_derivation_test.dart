import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/domain/entities/refuel_entry.dart';
import 'package:odolog/presentation/providers/refuel_form_provider.dart';
import 'package:odolog/presentation/providers/repositories.dart';

import '../helpers/entry_builder.dart';
import '../helpers/fake_refuel_repository.dart';

const _flowId = 'add:1';

/// A container whose form is bound to a repository seeded with [seed], with the
/// last price already resolved so the derivation rules can be driven and read
/// back synchronously.
Future<ProviderContainer> _formContainer(
  List<RefuelEntry> seed, {
  RefuelEntry? existing,
}) async {
  final container = ProviderContainer(
    overrides: [
      refuelRepositoryProvider.overrideWithValue(FakeRefuelRepository(seed)),
    ],
  );
  addTearDown(container.dispose);
  await container
      .read(refuelFormProvider(_flowId).notifier)
      .configure(vehicleId: 1, existing: existing);
  return container;
}

RefuelForm _form(ProviderContainer container) =>
    container.read(refuelFormProvider(_flowId).notifier);

RefuelFormState _state(ProviderContainer container) =>
    container.read(refuelFormProvider(_flowId));

void main() {
  test(
    'an amount derives litres into an empty quantity off the last price',
    () async {
      final container = await _formContainer([
        entry(id: 1, odometer: 1000, quantity: 10, pricePaid: 1000),
      ]);

      _form(container).setPrice('200');

      // Last price is 100 per litre, so 200 rupees is 2 litres.
      expect(_state(container).quantity, '2.00');
    },
  );

  test('the derivation clears when the amount is cleared', () async {
    final container = await _formContainer([
      entry(id: 1, odometer: 1000, quantity: 10, pricePaid: 1000),
    ]);

    _form(container).setPrice('200');
    _form(container).setPrice('');

    expect(_state(container).quantity, '');
  });

  test(
    'a manual quantity edit stops the derivation for the rest of the flow',
    () async {
      final container = await _formContainer([
        entry(id: 1, odometer: 1000, quantity: 10, pricePaid: 1000),
      ]);

      _form(container).setPrice('200');
      _form(container).setQuantity('5');
      _form(container).setPrice('300');

      expect(_state(container).quantity, '5');
    },
  );

  test('no last price means no derivation', () async {
    final container = await _formContainer(const []);

    _form(container).setPrice('200');

    expect(_state(container).lastPricePerUnit, isNull);
    expect(_state(container).quantity, '');
  });

  test('editing an existing entry never derives over its quantity', () async {
    final existing = entry(
      id: 1,
      odometer: 1000,
      quantity: 20,
      pricePaid: 2000,
    );
    final container = await _formContainer([existing], existing: existing);

    _form(container).setPrice('999');

    expect(_state(container).quantity, '20');
  });
}
