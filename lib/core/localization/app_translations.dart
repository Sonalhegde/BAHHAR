// BAHHAR App Translations — complete EN/AR dictionary
// All strings used throughout the app live here.
// Usage:  AppTranslations.t('key', isArabic)
// Dates/numbers: see locale_utils.dart

class AppTranslations {
  static const Map<String, Map<String, String>> _strings = {
    // ── App-wide ────────────────────────────────────────────────────
    'app_name': {'en': 'BAHHAR', 'ar': 'بَحّار'},
    'tagline': {'en': 'Your trusted companion at sea', 'ar': 'رفيقك الموثوق في البحر'},
    'language_en': {'en': 'EN', 'ar': 'EN'},
    'language_ar': {'en': 'عربي', 'ar': 'عربي'},
    'enter_command': {'en': 'Enter Command', 'ar': 'أدخل أمراً'},
    'oman': {'en': 'Oman', 'ar': 'عُمان'},
    'save': {'en': 'Save', 'ar': 'حفظ'},
    'cancel': {'en': 'Cancel', 'ar': 'إلغاء'},
    'edit': {'en': 'Edit', 'ar': 'تعديل'},
    'done': {'en': 'Done', 'ar': 'تم'},
    'confirm': {'en': 'Confirm', 'ar': 'تأكيد'},
    'delete': {'en': 'Delete', 'ar': 'حذف'},
    'add': {'en': 'Add', 'ar': 'إضافة'},
    'back': {'en': 'Back', 'ar': 'رجوع'},
    'yes': {'en': 'Yes', 'ar': 'نعم'},
    'no': {'en': 'No', 'ar': 'لا'},
    'loading': {'en': 'Loading…', 'ar': 'جارٍ التحميل…'},
    'error': {'en': 'Something went wrong', 'ar': 'حدث خطأ ما'},
    'retry': {'en': 'Retry', 'ar': 'إعادة المحاولة'},
    'optional': {'en': 'Optional', 'ar': 'اختياري'},
    'required': {'en': 'Required', 'ar': 'مطلوب'},
    'recommended': {'en': 'Recommended', 'ar': 'موصى به'},
    'verified': {'en': 'Verified', 'ar': 'موثّق'},
    'pending': {'en': 'Pending', 'ar': 'قيد الانتظار'},
    'active': {'en': 'Active', 'ar': 'نشط'},
    'expired': {'en': 'Expired', 'ar': 'منتهي الصلاحية'},
    'expiring_soon': {'en': 'Expiring Soon', 'ar': 'ينتهي قريباً'},
    'valid': {'en': 'Valid', 'ar': 'ساري'},
    'show': {'en': 'Show', 'ar': 'إظهار'},
    'hide': {'en': 'Hide', 'ar': 'إخفاء'},
    'search': {'en': 'Search', 'ar': 'بحث'},
    'select': {'en': 'Select', 'ar': 'اختر'},
    'view_all': {'en': 'View All', 'ar': 'عرض الكل'},
    'learn_more': {'en': 'Learn More', 'ar': 'اعرف المزيد'},
    'for_reference_only': {'en': 'Shown for reference only — official source', 'ar': 'للإشارة فقط — مصدر رسمي'},

    // ── Bottom Navigation ────────────────────────────────────────────
    'nav_command': {'en': 'Command', 'ar': 'الرئيسية'},
    'nav_chart': {'en': 'Chart', 'ar': 'الخريطة'},
    'nav_trip': {'en': 'Trip', 'ar': 'الرحلة'},
    'nav_logbook': {'en': 'Logbook', 'ar': 'السجل'},
    'nav_profile': {'en': 'Profile', 'ar': 'الملف'},

    // ── Home Dashboard ───────────────────────────────────────────────
    'good_morning': {'en': 'Good morning', 'ar': 'صباح الخير'},
    'good_afternoon': {'en': 'Good afternoon', 'ar': 'مساء الخير'},
    'good_evening': {'en': 'Good evening', 'ar': 'مساء النور'},
    'conditions_today': {'en': "Today's Conditions", 'ar': 'أحوال اليوم'},
    'wave_height': {'en': 'Waves', 'ar': 'الأمواج'},
    'wind_speed': {'en': 'Wind', 'ar': 'الرياح'},
    'water_temp': {'en': 'Water Temp', 'ar': 'حرارة الماء'},
    'fishing_score': {'en': 'Fishing Score', 'ar': 'مؤشر الصيد'},
    'recommended_hotspots': {'en': 'Recommended Spots', 'ar': 'مواقع مقترحة'},
    'no_data': {'en': 'No data available', 'ar': 'لا توجد بيانات'},
    'live_location_on': {'en': 'LIVE LOCATION ON', 'ar': 'الموقع المباشر مفعّل'},

    // ── Profile ──────────────────────────────────────────────────────
    'profile': {'en': 'Profile', 'ar': 'الملف الشخصي'},
    'profile_completion': {'en': 'Profile Completion', 'ar': 'اكتمال الملف'},
    'profile_complete': {'en': 'complete', 'ar': 'مكتمل'},
    'personal_info': {'en': 'Personal Information', 'ar': 'المعلومات الشخصية'},
    'full_name': {'en': 'Full Name', 'ar': 'الاسم الكامل'},
    'civil_id': {'en': 'Civil ID', 'ar': 'رقم الهوية المدنية'},
    'civil_id_hint': {'en': '••••••1234', 'ar': '••••••١٢٣٤'},
    'date_of_birth': {'en': 'Date of Birth', 'ar': 'تاريخ الميلاد'},
    'phone_number': {'en': 'Phone Number', 'ar': 'رقم الهاتف'},
    'email': {'en': 'Email', 'ar': 'البريد الإلكتروني'},
    'governorate': {'en': 'Governorate', 'ar': 'المحافظة'},
    'wilayat': {'en': 'Wilayat', 'ar': 'الولاية'},
    'address': {'en': 'Address', 'ar': 'العنوان'},
    'emergency_contact': {'en': 'Emergency Contact', 'ar': 'جهة الاتصال في الطوارئ'},
    'emergency_contact_name': {'en': 'Contact Name', 'ar': 'الاسم'},
    'emergency_contact_relation': {'en': 'Relationship', 'ar': 'العلاقة'},
    'emergency_contact_phone': {'en': 'Phone', 'ar': 'الهاتف'},
    'emergency_contact_alt_phone': {'en': 'Alternate Phone', 'ar': 'هاتف بديل'},

    // ── Fishing Section ──────────────────────────────────────────────
    'fishing_info': {'en': 'Fishing Information', 'ar': 'معلومات الصيد'},
    'fishing_licences': {'en': 'Fishing Licences', 'ar': 'تصاريح الصيد'},
    'add_licence': {'en': 'Add Licence', 'ar': 'إضافة تصريح'},
    'licence_number': {'en': 'Licence Number', 'ar': 'رقم التصريح'},
    'licence_type': {'en': 'Licence Type', 'ar': 'نوع التصريح'},
    'licence_expiry': {'en': 'Expiry Date', 'ar': 'تاريخ الانتهاء'},
    'licence_issue_date': {'en': 'Issue Date', 'ar': 'تاريخ الإصدار'},
    'licence_issuing_authority': {'en': 'Issuing Authority', 'ar': 'جهة الإصدار'},
    'licence_status': {'en': 'Status', 'ar': 'الحالة'},
    'days_until_expiry': {'en': 'days until expiry', 'ar': 'يوم حتى انتهاء الصلاحية'},
    'expired_days_ago': {'en': 'days ago', 'ar': 'منذ أيام'},

    // ── Vessels ──────────────────────────────────────────────────────
    'my_boats': {'en': 'My Boats', 'ar': 'قواربي'},
    'add_boat': {'en': 'Add Boat', 'ar': 'إضافة قارب'},
    'boat_name': {'en': 'Boat Name', 'ar': 'اسم القارب'},
    'boat_registration': {'en': 'Registration Number', 'ar': 'رقم التسجيل'},
    'boat_type': {'en': 'Boat Type', 'ar': 'نوع القارب'},
    'boat_length': {'en': 'Length', 'ar': 'الطول'},
    'boat_engine_hp': {'en': 'Engine (HP)', 'ar': 'المحرك (حصان)'},
    'boat_nav_licence': {'en': 'Navigation Licence', 'ar': 'ترخيص الملاحة'},
    'boat_inspection': {'en': 'Last Inspection', 'ar': 'آخر فحص'},
    'boat_capacity': {'en': 'Capacity (persons)', 'ar': 'السعة (أشخاص)'},
    'boat_color': {'en': 'Boat Color', 'ar': 'لون القارب'},

    // ── Crew ─────────────────────────────────────────────────────────
    'crew': {'en': 'Crew Members', 'ar': 'أفراد الطاقم'},
    'add_crew': {'en': 'Add Crew Member', 'ar': 'إضافة فرد'},
    'crew_name': {'en': 'Name', 'ar': 'الاسم'},
    'crew_role': {'en': 'Role', 'ar': 'الدور'},
    'crew_civil_id': {'en': 'Civil ID', 'ar': 'رقم الهوية'},
    'crew_phone': {'en': 'Phone', 'ar': 'الهاتف'},
    'crew_licence': {'en': 'Fishing Licence', 'ar': 'تصريح الصيد'},
    'crew_emergency_contact': {'en': 'Emergency Contact', 'ar': 'جهة الطوارئ'},

    // ── Fishing Gear ─────────────────────────────────────────────────
    'fishing_gear': {'en': 'Fishing Gear & Permits', 'ar': 'معدات وتصاريح الصيد'},
    'gear_type': {'en': 'Gear Type', 'ar': 'نوع المعدة'},
    'gear_permit': {'en': 'Gear Permit', 'ar': 'تصريح المعدة'},
    'gear_permit_number': {'en': 'Permit Number', 'ar': 'رقم التصريح'},
    'gear_permit_expiry': {'en': 'Permit Expiry', 'ar': 'انتهاء التصريح'},

    // ── Documents Wallet ─────────────────────────────────────────────
    'documents': {'en': 'Documents', 'ar': 'المستندات'},
    'documents_wallet': {'en': 'Documents Wallet', 'ar': 'محفظة المستندات'},
    'add_document': {'en': 'Add Document', 'ar': 'إضافة مستند'},
    'document_type': {'en': 'Document Type', 'ar': 'نوع المستند'},
    'document_number': {'en': 'Document Number', 'ar': 'رقم المستند'},
    'document_expiry': {'en': 'Expiry', 'ar': 'الانتهاء'},
    'document_scan': {'en': 'Scan / Photo', 'ar': 'مسح / صورة'},
    'expires_in': {'en': 'Expires in', 'ar': 'ينتهي في'},
    'days': {'en': 'days', 'ar': 'أيام'},

    // ── Safety Center ─────────────────────────────────────────────────
    'safety_center': {'en': 'Safety Center', 'ar': 'مركز السلامة'},
    'pre_departure_checklist': {'en': 'Pre-Departure Checklist', 'ar': 'قائمة ما قبل الإقلاع'},
    'checklist_life_jackets': {'en': 'Life jackets for all crew', 'ar': 'سترات النجاة لجميع أفراد الطاقم'},
    'checklist_fuel': {'en': 'Fuel check — sufficient for trip + return', 'ar': 'فحص الوقود — كافٍ للرحلة والعودة'},
    'checklist_engine': {'en': 'Engine check and start test', 'ar': 'فحص المحرك واختبار التشغيل'},
    'checklist_nav_equipment': {'en': 'Navigation equipment functional', 'ar': 'معدات الملاحة تعمل'},
    'checklist_comms': {'en': 'Communications device charged', 'ar': 'جهاز الاتصالات مشحون'},
    'checklist_emergency_gear': {'en': 'Emergency flares and signals', 'ar': 'مشاعل الطوارئ والإشارات'},
    'checklist_water': {'en': 'Fresh water and food supplies', 'ar': 'المياه العذبة والمؤن'},
    'checklist_documents': {'en': 'All licences and documents on board', 'ar': 'جميع التراخيص والمستندات على متن القارب'},
    'checklist_weather': {'en': 'Weather forecast checked', 'ar': 'تم التحقق من توقعات الطقس'},
    'checklist_float_plan': {'en': 'Float plan shared with shore contact', 'ar': 'تمت مشاركة خطة الإبحار مع جهة الاتصال البرية'},
    'safety_complete': {'en': 'All checks complete — safe voyage!', 'ar': 'جميع الفحوصات مكتملة — رحلة آمنة!'},
    'safety_incomplete': {'en': 'items remaining', 'ar': 'بنود متبقية'},

    // ── Location ──────────────────────────────────────────────────────
    'location': {'en': 'Location', 'ar': 'الموقع'},
    'location_off': {'en': 'Off', 'ar': 'معطّل'},
    'location_map_only': {'en': 'On for Map', 'ar': 'مفعّل للخريطة'},
    'location_active_trip': {'en': 'On for Active Trip', 'ar': 'مفعّل للرحلة النشطة'},
    'location_privacy': {'en': 'Location Privacy', 'ar': 'خصوصية الموقع'},
    'location_privacy_desc': {
      'en': 'Your location is used only for navigation assistance and trip tracking. It is never shared with third parties without your explicit consent.',
      'ar': 'يُستخدم موقعك فقط للمساعدة في التنقل وتتبع الرحلات. لا يُشارك أبداً مع أطراف ثالثة دون موافقتك الصريحة.'
    },

    // ── Report an Issue ───────────────────────────────────────────────
    'report_issue': {'en': 'Report an Issue', 'ar': 'الإبلاغ عن مشكلة'},
    'issue_category': {'en': 'Category', 'ar': 'الفئة'},
    'issue_description': {'en': 'Description', 'ar': 'الوصف'},
    'issue_id': {'en': 'Reference ID', 'ar': 'رقم المرجع'},
    'issue_status': {'en': 'Status', 'ar': 'الحالة'},
    'issue_submitted': {'en': 'Issue Submitted', 'ar': 'تم تقديم البلاغ'},
    'issue_under_review': {'en': 'Under Review', 'ar': 'قيد المراجعة'},
    'issue_resolved': {'en': 'Resolved', 'ar': 'تم الحل'},
    'issue_cat_app': {'en': 'App Problem', 'ar': 'مشكلة في التطبيق'},
    'issue_cat_data': {'en': 'Incorrect Data', 'ar': 'بيانات غير صحيحة'},
    'issue_cat_safety': {'en': 'Safety Concern', 'ar': 'مخاوف السلامة'},
    'issue_cat_map': {'en': 'Map / Location', 'ar': 'الخريطة / الموقع'},
    'issue_cat_other': {'en': 'Other', 'ar': 'أخرى'},

    // ── Help & Instructions ───────────────────────────────────────────
    'help': {'en': 'Help & Instructions', 'ar': 'المساعدة والتعليمات'},
    'help_how_to_use': {'en': 'How to Use', 'ar': 'كيفية الاستخدام'},
    'help_trip_planning': {'en': 'Trip Planning', 'ar': 'التخطيط للرحلة'},
    'help_catch_logging': {'en': 'Logging Your Catch', 'ar': 'تسجيل صيدك'},
    'help_map': {'en': 'Using the Map', 'ar': 'استخدام الخريطة'},
    'help_safety': {'en': 'Safety Features', 'ar': 'ميزات السلامة'},
    'help_documents': {'en': 'Managing Documents', 'ar': 'إدارة المستندات'},
    'help_language': {'en': 'Changing Language', 'ar': 'تغيير اللغة'},
    'help_offline': {'en': 'Using Offline', 'ar': 'الاستخدام بدون إنترنت'},
    'help_contact_support': {'en': 'Contact Support', 'ar': 'التواصل مع الدعم'},

    // ── Official Info ─────────────────────────────────────────────────
    'official_info': {'en': 'Official Fishing Information', 'ar': 'معلومات الصيد الرسمية'},
    'official_info_source': {'en': 'Ministry of Agriculture, Fisheries and Water Resources — Oman', 'ar': 'وزارة الزراعة والثروة السمكية وموارد المياه — عُمان'},
    'official_info_disclaimer': {
      'en': 'Information shown here is for reference only and is sourced from official Omani government publications. Always verify with the relevant authority.',
      'ar': 'المعلومات الواردة هنا للإشارة فقط وهي مستقاة من المنشورات الحكومية العُمانية الرسمية. يُرجى التحقق دائماً مع الجهة المختصة.'
    },

    // ── Settings ──────────────────────────────────────────────────────
    'settings': {'en': 'Settings', 'ar': 'الإعدادات'},
    'settings_language': {'en': 'Language', 'ar': 'اللغة'},
    'settings_units': {'en': 'Units', 'ar': 'الوحدات'},
    'settings_units_metric': {'en': 'Metric (kg, m, °C)', 'ar': 'متري (كغ، م، °م)'},
    'settings_units_imperial': {'en': 'Imperial (lb, ft, °F)', 'ar': 'إمبراطوري (رطل، قدم، °ف)'},
    'settings_notifications': {'en': 'Notifications', 'ar': 'الإشعارات'},
    'settings_privacy': {'en': 'Privacy', 'ar': 'الخصوصية'},
    'settings_location': {'en': 'Location', 'ar': 'الموقع'},
    'settings_map': {'en': 'Map', 'ar': 'الخريطة'},
    'settings_trip': {'en': 'Trip', 'ar': 'الرحلة'},
    'settings_safety': {'en': 'Safety', 'ar': 'السلامة'},
    'settings_account': {'en': 'Account', 'ar': 'الحساب'},
    'settings_help': {'en': 'Help', 'ar': 'المساعدة'},
    'settings_about': {'en': 'About BAHHAR', 'ar': 'عن بَحّار'},
    'settings_sign_out': {'en': 'Sign Out', 'ar': 'تسجيل الخروج'},
    'settings_delete_account': {'en': 'Delete Account', 'ar': 'حذف الحساب'},

    // ── Governorates ──────────────────────────────────────────────────
    'gov_muscat': {'en': 'Muscat', 'ar': 'مسقط'},
    'gov_dhofar': {'en': 'Dhofar', 'ar': 'ظفار'},
    'gov_musandam': {'en': 'Musandam', 'ar': 'مسندم'},
    'gov_alwusta': {'en': 'Al Wusta', 'ar': 'الوسطى'},
    'gov_northbatinah': {'en': 'North Al Batinah', 'ar': 'شمال الباطنة'},
    'gov_southbatinah': {'en': 'South Al Batinah', 'ar': 'جنوب الباطنة'},
    'gov_northsharqiyah': {'en': 'North Al Sharqiyah', 'ar': 'شمال الشرقية'},
    'gov_southsharqiyah': {'en': 'South Al Sharqiyah', 'ar': 'جنوب الشرقية'},
    'gov_aldakhiliyah': {'en': 'Al Dakhiliyah', 'ar': 'الداخلية'},
    'gov_alburaimi': {'en': 'Al Buraimi', 'ar': 'البريمي'},
    'gov_alzahirah': {'en': 'Al Zahirah', 'ar': 'الظاهرة'},
  };

  /// Returns the translated string for [key] in the appropriate language.
  static String t(String key, bool isArabic) {
    final entry = _strings[key];
    if (entry == null) return key;
    return isArabic ? (entry['ar'] ?? entry['en'] ?? key) : (entry['en'] ?? key);
  }

  /// All Oman governorates (english name, translation key)
  static const List<Map<String, String>> governorates = [
    {'en': 'Muscat', 'key': 'gov_muscat'},
    {'en': 'Dhofar', 'key': 'gov_dhofar'},
    {'en': 'Musandam', 'key': 'gov_musandam'},
    {'en': 'Al Wusta', 'key': 'gov_alwusta'},
    {'en': 'North Al Batinah', 'key': 'gov_northbatinah'},
    {'en': 'South Al Batinah', 'key': 'gov_southbatinah'},
    {'en': 'North Al Sharqiyah', 'key': 'gov_northsharqiyah'},
    {'en': 'South Al Sharqiyah', 'key': 'gov_southsharqiyah'},
    {'en': 'Al Dakhiliyah', 'key': 'gov_aldakhiliyah'},
    {'en': 'Al Buraimi', 'key': 'gov_alburaimi'},
    {'en': 'Al Zahirah', 'key': 'gov_alzahirah'},
  ];
}
