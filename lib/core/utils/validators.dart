/// Input and authentication validators.
///
/// Return `null` when the value is valid, or a human-readable (localized)
/// error string when it is not — matching the contract expected by
/// Flutter's `TextFormField.validator`.
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$",
  );

  /// Strips spaces, dashes and parentheses so we validate the raw digits.
  static String _clean(String value) =>
      value.replaceAll(RegExp(r'[\s\-()]'), '');

  /// Required, non-empty field.
  static String? required(String? value, {bool isArabic = false}) {
    if (value == null || value.trim().isEmpty) {
      return isArabic ? 'هذا الحقل مطلوب' : 'This field is required';
    }
    return null;
  }

  /// Oman mobile / landline number.
  ///
  /// Accepts an optional `+968` or `00968` country code followed by an
  /// 8-digit national number. Omani mobiles begin with 7 or 9; landlines
  /// begin with 2. Empty is allowed unless [requiredField] is true.
  static String? omanPhone(
    String? value, {
    bool isArabic = false,
    bool requiredField = true,
  }) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      if (requiredField) {
        return isArabic ? 'رقم الهاتف مطلوب' : 'Phone number is required';
      }
      return null;
    }

    var digits = _clean(raw);
    if (digits.startsWith('+968')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('00968')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('968') && digits.length == 11) {
      digits = digits.substring(3);
    }

    final valid = RegExp(r'^[279]\d{7}$').hasMatch(digits);
    if (!valid) {
      return isArabic
          ? 'رقم عُماني غير صالح (٨ أرقام يبدأ بـ ٧ أو ٩)'
          : 'Enter a valid Oman number (8 digits, starting 7 or 9)';
    }
    return null;
  }

  /// Email address. Empty is allowed unless [requiredField] is true.
  static String? email(
    String? value, {
    bool isArabic = false,
    bool requiredField = false,
  }) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      if (requiredField) {
        return isArabic ? 'البريد الإلكتروني مطلوب' : 'Email is required';
      }
      return null;
    }
    if (!_emailRegex.hasMatch(raw)) {
      return isArabic
          ? 'صيغة البريد الإلكتروني غير صحيحة'
          : 'Enter a valid email address';
    }
    return null;
  }

  /// Omani Civil ID — an 8-digit numeric identifier.
  static String? civilId(String? value, {bool isArabic = false}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return isArabic ? 'الرقم المدني مطلوب' : 'Civil ID is required';
    }
    if (!RegExp(r'^\d{8}$').hasMatch(_clean(raw))) {
      return isArabic
          ? 'الرقم المدني يجب أن يكون ٨ أرقام'
          : 'Civil ID must be 8 digits';
    }
    return null;
  }

  /// A person's name — at least two characters, letters only (Latin or Arabic).
  static String? name(
    String? value, {
    bool isArabic = false,
    bool requiredField = true,
  }) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      if (requiredField) {
        return isArabic ? 'الاسم مطلوب' : 'Name is required';
      }
      return null;
    }
    if (raw.length < 2) {
      return isArabic ? 'الاسم قصير جداً' : 'Name is too short';
    }
    return null;
  }

  /// Password with a minimum length (default 8).
  static String? password(
    String? value, {
    int minLength = 8,
    bool isArabic = false,
  }) {
    final raw = value ?? '';
    if (raw.isEmpty) {
      return isArabic ? 'كلمة المرور مطلوبة' : 'Password is required';
    }
    if (raw.length < minLength) {
      return isArabic
          ? 'كلمة المرور يجب أن تكون $minLength أحرف على الأقل'
          : 'Password must be at least $minLength characters';
    }
    return null;
  }
}
