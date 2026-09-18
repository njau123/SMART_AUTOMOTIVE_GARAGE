/// Validation helpers kwa Tanzania.
class Validators {
  Validators._();

  /// Phone ya Tanzania: 06XXXXXXXX au 07XXXXXXXX (tarakimu 10 jumla).
  /// Pia inaruhusu +2556XXXXXXXX au +2557XXXXXXXX.
  static String? phoneTanzania(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final clean = value.replaceAll(RegExp(r'[\s\-]'), '');

    // Aina +255...
    if (clean.startsWith('+255')) {
      final rest = clean.substring(4);
      if (rest.length != 9) return 'Number must have 9 digits after +255';
      if (!RegExp(r'^[67]\d{8}$').hasMatch(rest)) {
        return 'Must start with 6 or 7 after +255';
      }
      return null;
    }

    // Aina 06... au 07...
    if (clean.startsWith('06') || clean.startsWith('07')) {
      if (clean.length != 10) return 'Number must be 10 digits (0XXXXXXXXX)';
      if (!RegExp(r'^0[67]\d{8}$').hasMatch(clean)) {
        return 'Invalid phone number';
      }
      return null;
    }

    return 'Start with 06, 07, or +255';
  }

  /// Vehicle registration ya Tanzania: T123 ABC au T 123 ABC
  /// Format: 1 letter (T), 3 digits, 3 letters.
  static String? vehicleRegTanzania(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Registration number is required';
    }
    // Ondoa nafasi zote, weka uppercase
    final clean = value.replaceAll(RegExp(r'\s'), '').toUpperCase();

    // Format: [Letter][3 digits][3 letters]
    final regex = RegExp(r'^[A-Z]\d{3}[A-Z]{3}$');
    if (!regex.hasMatch(clean)) {
      return 'Format: T123 ABC (letter + 3 digits + 3 letters)';
    }
    return null;
  }

  /// Jina (first, middle, last).
  static String? name(String? value, {String field = 'Name', bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$field is required' : null;
    }
    if (value.trim().length < 2) return '$field too short';
    return null;
  }

  /// Email.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$');
    if (!regex.hasMatch(value.trim())) return 'Invalid email';
    return null;
  }

  /// Password.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'At least 6 characters';
    return null;
  }

  /// Vehicle year (1950 - sasa).
  static String? vehicleYear(String? value) {
    if (value == null || value.trim().isEmpty) return 'Year is required';
    final year = int.tryParse(value.trim());
    if (year == null) return 'Year must be a number';
    final currentYear = DateTime.now().year;
    if (year < 1950 || year > currentYear) {
      return 'Year must be between 1950 and $currentYear';
    }
    return null;
  }

  /// Fomati ya vehicle reg kwa display: "T123ABC" → "T123 ABC"
  static String formatReg(String value) {
    final clean = value.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (clean.length == 7) {
      return '${clean.substring(0, 4)} ${clean.substring(4)}';
    }
    return value;
  }
}
