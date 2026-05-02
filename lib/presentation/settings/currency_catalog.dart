/// One entry in the currency picker: the symbol the app renders everywhere
/// money is shown, paired with a name so the picker can tell apart two
/// currencies that share a symbol.
class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String code;
  final String symbol;
  final String name;
}

/// A curated list of common currencies for the settings picker. India is the
/// default market, so the rupee leads; a stored symbol that matches none of
/// these (a custom value from before the picker existed, or one hand edited
/// into shared preferences) still displays and still works, it just will not
/// highlight an entry in the sheet.
const currencyCatalog = [
  CurrencyOption(code: 'INR', symbol: 'Rs', name: 'Indian Rupee'),
  CurrencyOption(code: 'USD', symbol: r'$', name: 'US Dollar'),
  CurrencyOption(code: 'EUR', symbol: '€', name: 'Euro'),
  CurrencyOption(code: 'GBP', symbol: '£', name: 'British Pound'),
  CurrencyOption(code: 'AED', symbol: 'Dh', name: 'UAE Dirham'),
  CurrencyOption(code: 'SAR', symbol: 'SR', name: 'Saudi Riyal'),
  CurrencyOption(code: 'SGD', symbol: r'S$', name: 'Singapore Dollar'),
  CurrencyOption(code: 'AUD', symbol: r'A$', name: 'Australian Dollar'),
  CurrencyOption(code: 'CAD', symbol: r'C$', name: 'Canadian Dollar'),
  CurrencyOption(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  CurrencyOption(code: 'NPR', symbol: 'NRs', name: 'Nepalese Rupee'),
  CurrencyOption(code: 'LKR', symbol: 'SLRs', name: 'Sri Lankan Rupee'),
];
