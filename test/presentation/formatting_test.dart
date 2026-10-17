import 'package:flutter_test/flutter_test.dart';
import 'package:odolog/presentation/common/formatting.dart';

void main() {
  test('money groups thousands and always shows two decimals', () {
    expect(formatMoney(6617.97, 'Rs'), 'Rs 6,617.97');
    expect(formatMoney(1234567.5, 'Rs'), 'Rs 1,234,567.50');
    expect(formatMoney(95, 'Rs'), 'Rs 95.00');
    expect(formatMoneyPerKm(3.02, 'Rs'), 'Rs 3.02 /km');
    expect(formatMoneyPerKm(1234.5, 'Rs'), 'Rs 1,234.50 /km');
  });
}
