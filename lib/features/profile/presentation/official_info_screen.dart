import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/theme/app_colors.dart';

class OfficialInfoScreen extends ConsumerWidget {
  const OfficialInfoScreen({super.key});

  static const _sections = [
    {
      'title_en': 'Fishing Seasons',
      'title_ar': 'مواسم الصيد',
      'content_en':
          'Oman regulates fishing seasons to protect breeding populations. Certain species have defined closed seasons. Always check current Ministry circulars for the latest dates.',
      'content_ar':
          'تنظم عُمان مواسم الصيد لحماية مجتمعات التكاثر. بعض الأنواع لها فترات إغلاق محددة. تحقق دائماً من آخر تعميمات الوزارة للاطلاع على أحدث التواريخ.',
    },
    {
      'title_en': 'Protected Marine Areas',
      'title_ar': 'المناطق البحرية المحمية',
      'content_en':
          'The Daymaniyat Islands, Ras Al Hadd, and other designated reserves are protected under Omani law. Fishing within these zones is prohibited or restricted. Violations are subject to fines and confiscation.',
      'content_ar':
          'تخضع جزر الديمانيات ورأس الحد وغيرها من المحميات المخصصة للحماية بموجب القانون العُماني. الصيد داخل هذه المناطق محظور أو مقيد. المخالفات عرضة للغرامات والمصادرة.',
    },
    {
      'title_en': 'Fishing Licence Requirements',
      'title_ar': 'متطلبات تصريح الصيد',
      'content_en':
          'Commercial and artisanal fishing licences are issued by the Ministry of Agriculture, Fisheries and Water Resources (MAFWR). Licence type and eligibility depend on vessel class and fishing method. This information is shown for reference — always confirm with MAFWR.',
      'content_ar':
          'تصدر تصاريح الصيد التجاري والحرفي عن وزارة الزراعة والثروة السمكية وموارد المياه. يعتمد نوع التصريح والأهلية على فئة السفينة وأسلوب الصيد. هذه المعلومات للإشارة فقط — يرجى دائماً التأكد من الوزارة.',
    },
    {
      'title_en': 'Gear Regulations',
      'title_ar': 'لوائح المعدات',
      'content_en':
          'Certain fishing gear types (e.g., trawling nets in shallow areas) are prohibited in Omani waters. Only licensed gear may be used. Gear permits are separate from fishing licences.',
      'content_ar':
          'أنواع معينة من معدات الصيد (مثل شباك الجرف في المناطق الضحلة) محظورة في المياه العُمانية. يُسمح فقط باستخدام المعدات المرخصة. تصاريح المعدات منفصلة عن تصاريح الصيد.',
    },
    {
      'title_en': 'Emergency Contacts',
      'title_ar': 'جهات الاتصال للطوارئ',
      'content_en':
          'MRCC Oman (Maritime Rescue Coordination Centre): +968 2473 0066\n'
          'Royal Oman Police – Coast Guard: 9999\n'
          'Ministry of Agriculture Fisheries Hotline: 80077400',
      'content_ar':
          'مركز تنسيق الإنقاذ البحري عُمان (MRCC): ٩٦٨٢٤٧٣٠٠٦٦+\n'
          'شرطة عُمان السلطانية - خفر السواحل: ٩٩٩٩\n'
          'خط وزارة الزراعة والثروة السمكية الساخن: ٨٠٠٧٧٤٠٠',
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArabic = ref.watch(isArabicProvider);
    String t(String k) => AppTranslations.t(k, isArabic);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      appBar: AppBar(
        title: Text(t('official_info')),
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Source badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_outlined, color: AppColors.primaryBlue, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('official_info_source'),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('official_info_disclaimer'),
                        style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF3A5A80)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          ..._sections.map((section) => _InfoSection(section: section, isArabic: isArabic)),

          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _InfoSection extends StatefulWidget {
  final Map<String, String> section;
  final bool isArabic;
  const _InfoSection({required this.section, required this.isArabic});

  @override
  State<_InfoSection> createState() => _InfoSectionState();
}

class _InfoSectionState extends State<_InfoSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.isArabic ? widget.section['title_ar']! : widget.section['title_en']!;
    final content = widget.isArabic ? widget.section['content_ar']! : widget.section['content_en']!;

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
                  const Icon(Icons.article_outlined, size: 20, color: AppColors.primaryBlue),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F4F8)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Text(content, style: const TextStyle(fontSize: 13, height: 1.6, color: Colors.black87)),
            ),
          ],
        ],
      ),
    );
  }
}
