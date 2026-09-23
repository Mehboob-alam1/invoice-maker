class CurrencyFormat {
  CurrencyFormat._();

  static String symbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'PKR':
        return 'Rs ';
      case 'INR':
        return '₹';
      case 'CAD':
        return 'CA\$';
      case 'AUD':
        return 'A\$';
      case 'AED':
        return 'AED ';
      case 'JPY':
        return '¥';
      case 'CHF':
        return 'CHF ';
      default:
        return '$code ';
    }
  }

  static String format(String currencyCode, double amount) {
    final sym = symbol(currencyCode);
    final decimals = currencyCode.toUpperCase() == 'JPY' ? 0 : 2;
    return '$sym${amount.toStringAsFixed(decimals)}';
  }

  static const supportedCodes = [
    'USD',
    'EUR',
    'GBP',
    'PKR',
    'INR',
    'CAD',
    'AUD',
    'AED',
    'JPY',
    'CHF',
  ];
}
