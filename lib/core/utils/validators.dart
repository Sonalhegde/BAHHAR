/// Input and authentication validators
class Validators {
  Validators._();

  /// Validates Oman phone numbers (+968 format)
  /// Accepts formats: +96812345678, 96812345678, 12345678
  static String? validateOmanPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'[\s-]'), '');
    
    // Oman mobile numbers: 8 digits starting with 9, 7, or 2
    // Landline: 8 digits starting with 2
    final phoneRegex = RegExp(r'^(\+?968)?([97][0-9]{7}|2[0-9]{7})$');
    
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Invalid Oman phone number. Must be 8 digits starting with 9, 7, or 2';
    }
    
    return null;
  }

  /// Validates email addresses
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email address';
    }

    return null;
  }

  /// Validates password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  /// Validates required text fields
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates positive numbers
  static String? validatePositiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final number = double.tryParse(value);
    if (number == null || number <= 0) {
      return '$fieldName must be a positive number';
    }

    return null;
  }

  /// Validates coordinates (latitude)
  static String? validateLatitude(String? value) {
    if (value == null || value.isEmpty) {
      return 'Latitude is required';
    }

    final lat = double.tryParse(value);
    if (lat == null || lat < -90 || lat > 90) {
      return 'Latitude must be between -90 and 90';
    }

    return null;
  }

  /// Validates coordinates (longitude)
  static String? validateLongitude(String? value) {
    if (value == null || value.isEmpty) {
      return 'Longitude is required';
    }

    final lon = double.tryParse(value);
    if (lon == null || lon < -180 || lon > 180) {
      return 'Longitude must be between -180 and 180';
    }

    return null;
  }
}
