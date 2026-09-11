import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';

class HelpInstructionsScreen extends ConsumerWidget {
  const HelpInstructionsScreen({super.key});

  static const List<Map<String, dynamic>> _topics = [
    {
      'key': 'help_how_to_use',
      'icon': Icons.home_outlined,
      'steps_en': [
        'Open the Command screen — this is your main dashboard.',
        'Check today\'s fishing conditions: wave height, wind speed, water temperature.',
        'Use the Fishing Score gauge to decide if it\'s a good day to go out.',
        'Tap a recommended hotspot to see its details on the map.',
      ],
      'steps_ar': [
        'افتح شاشة الرئيسية — هذه لوحة التحكم الرئيسية.',
        'تحقق من أحوال الصيد اليوم: ارتفاع الأمواج، سرعة الرياح، درجة حرارة الماء.',
        'استخدم مقياس مؤشر الصيد لتحديد ما إذا كان اليوم مناسباً للخروج.',
        'اضغط على موقع مقترح لرؤية تفاصيله على الخريطة.',
      ],
    },
    {
      'key': 'help_trip_planning',
      'icon': Icons.explore_outlined,
      'steps_en': [
        'Go to the Trip screen.',
        'Select your governorate and target species.',
        'Bahhar will recommend the best spots based on current conditions.',
        'Review the trip details — estimated travel time, distance, depth.',
        'Save the trip or start navigation.',
      ],
      'steps_ar': [
        'انتقل إلى شاشة الرحلة.',
        'اختر محافظتك والأنواع المستهدفة.',
        'سيوصي بَحّار بأفضل المواقع بناءً على الأحوال الراهنة.',
        'راجع تفاصيل الرحلة — وقت السفر المقدر والمسافة والعمق.',
        'احفظ الرحلة أو ابدأ الملاحة.',
      ],
    },
    {
      'key': 'help_catch_logging',
      'icon': Icons.phishing_outlined,
      'steps_en': [
        'Go to the Logbook screen.',
        'Tap the + button to add a new catch entry.',
        'Enter species, weight, length, and location.',
        'Optionally add notes or lure type used.',
        'Save — your catch history builds over time.',
      ],
      'steps_ar': [
        'انتقل إلى شاشة السجل.',
        'اضغط على زر + لإضافة سجل صيد جديد.',
        'أدخل النوع والوزن والطول والموقع.',
        'أضف ملاحظات اختيارية أو نوع الطُعم المستخدم.',
        'احفظ — يتراكم سجل صيدك بمرور الوقت.',
      ],
    },
    {
      'key': 'help_map',
      'icon': Icons.map_outlined,
      'steps_en': [
        'Go to the Chart screen.',
        'Blue markers show fishing hotspots.',
        'Red markers show protected marine areas — fishing is restricted there.',
        'Tap any marker for details: species, depth, distance.',
        'Use pinch-to-zoom and drag to navigate the map.',
      ],
      'steps_ar': [
        'انتقل إلى شاشة الخريطة.',
        'تشير العلامات الزرقاء إلى مواقع الصيد الساخنة.',
        'تشير العلامات الحمراء إلى المناطق البحرية المحمية — الصيد مقيد هناك.',
        'اضغط على أي علامة للحصول على التفاصيل: الأنواع والعمق والمسافة.',
        'استخدم التكبير بالضغط وسحب الخريطة للتنقل.',
      ],
    },
    {
      'key': 'help_safety',
      'icon': Icons.security_outlined,
      'steps_en': [
        'Go to Profile → Safety Center.',
        'Complete the Pre-Departure Checklist before every trip.',
        'Make sure your Emergency Contact is set in your profile.',
        'Enable Live Location for Active Trip when at sea.',
        'In an emergency, contact the MRCC Oman: +968 2473 0066.',
      ],
      'steps_ar': [
        'انتقل إلى الملف الشخصي → مركز السلامة.',
        'أكمل قائمة ما قبل الإقلاع قبل كل رحلة.',
        'تأكد من تعيين جهة الاتصال في حالات الطوارئ في ملفك الشخصي.',
        'فعّل الموقع المباشر للرحلة النشطة عند التواجد في البحر.',
        'في حالات الطوارئ، تواصل مع مركز تنسيق الإنقاذ البحري عُمان: ٠٠٩٦٨٢٤٧٣٠٠٦٦.',
      ],
    },
    {
      'key': 'help_documents',
      'icon': Icons.folder_outlined,
      'steps_en': [
        'Go to Profile → Documents.',
        'Tap + to add a document — enter type, number, and expiry date.',
        'Documents expiring within 30 days show an orange warning.',
        'Expired documents show in red at the top of the list.',
        'You will receive reminder notifications at 30, 14, 7, and 1 day before expiry.',
      ],
      'steps_ar': [
        'انتقل إلى الملف الشخصي → المستندات.',
        'اضغط + لإضافة مستند — أدخل النوع والرقم وتاريخ الانتهاء.',
        'تُعرض المستندات التي تنتهي صلاحيتها خلال 30 يوماً بتحذير برتقالي.',
        'تظهر المستندات المنتهية باللون الأحمر في أعلى القائمة.',
        'ستتلقى إشعارات تذكير قبل 30 و14 و7 و1 يوم من انتهاء الصلاحية.',
      ],
    },
    {
      'key': 'help_language',
      'icon': Icons.language_outlined,
      'steps_en': [
        'Go to Profile → Settings → Language.',
        'Select العربية for Arabic or English.',
        'The app switches immediately — no restart needed.',
        'Arabic mode uses full RTL layout and Arabic-Indic numerals.',
        'You can also toggle language from the splash screen.',
      ],
      'steps_ar': [
        'انتقل إلى الملف الشخصي → الإعدادات → اللغة.',
        'اختر العربية أو الإنجليزية.',
        'يتحول التطبيق فوراً — لا حاجة لإعادة التشغيل.',
        'يستخدم الوضع العربي التخطيط من اليمين إلى اليسار والأرقام العربية الهندية.',
        'يمكنك أيضاً تبديل اللغة من شاشة البداية.',
      ],
    },
    {
      'key': 'help_offline',
      'icon': Icons.wifi_off_outlined,
      'steps_en': [
        'Bahhar stores your profile data locally on your device.',
        'Without internet: you can still access your profile, documents metadata, emergency contacts, last known trip state, and safety checklist.',
        'Map tiles require internet for initial download.',
        'Weather conditions require internet.',
        'When reconnected, data syncs automatically.',
      ],
      'steps_ar': [
        'يخزن بَحّار بيانات ملفك الشخصي محلياً على جهازك.',
        'بدون إنترنت: يمكنك الوصول إلى ملفك الشخصي وبيانات المستندات وجهات الطوارئ وحالة الرحلة الأخيرة وقائمة السلامة.',
        'تحتاج بلاطات الخريطة إلى إنترنت للتحميل الأولي.',
        'تتطلب أحوال الطقس إنترنت.',
        'عند إعادة الاتصال، تتزامن البيانات تلقائياً.',
      ],
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: Text(t('help')),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.support_agent_rounded, color: AppColors.primaryBlue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isArabic ? 'للمساعدة الفورية، تواصل مع الدعم عبر البريد: support@bahhar.app' : 'For immediate help, contact support at: support@bahhar.app',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._topics.map((topic) => _HelpTopic(
            topic: topic,
            isArabic: isArabic,
            label: t(topic['key'] as String),
          )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _HelpTopic extends StatefulWidget {
  final Map<String, dynamic> topic;
  final bool isArabic;
  final String label;
  const _HelpTopic({required this.topic, required this.isArabic, required this.label});

  @override
  State<_HelpTopic> createState() => _HelpTopicState();
}

class _HelpTopicState extends State<_HelpTopic> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final steps = widget.isArabic
        ? (widget.topic['steps_ar'] as List<String>)
        : (widget.topic['steps_en'] as List<String>);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2EDF8)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(widget.topic['icon'] as IconData, size: 20, color: AppColors.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(child: Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F4F8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryBlue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(e.value, style: const TextStyle(fontSize: 13, height: 1.5)),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
