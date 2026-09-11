import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/glass_tokens.dart';
import '../../../core/providers/notifications_provider.dart';
import '../../../shared/widgets/alert_banner.dart' show AlertSeverity;
import '../../../shared/glass/marine_background.dart';
import '../../../shared/glass/glass_container.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return MarineBackground(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
            title: Text('Marine Advisories & Alerts', style: AppTextStyles.subhead.copyWith(color: Colors.white)),
          ),

          (() {
              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, idx) {
                      final n = notifications[idx];
                      final isSafety = n.severity == AlertSeverity.warning || n.severity == AlertSeverity.danger;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassContainer(
                          level: GlassLevel.standard,
                          borderRadius: GlassTokens.radiusMedium,
                          padding: const EdgeInsets.all(16),
                          customColor: isSafety
                              ? AppColors.signalAlert.withValues(alpha: 0.12)
                              : null,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSafety
                                      ? AppColors.signalAlert.withValues(alpha: 0.2)
                                      : AppColors.cyanAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  isSafety ? Icons.warning_amber_rounded : Icons.notifications_outlined,
                                  size: 20,
                                  color: isSafety ? AppColors.signalAlert : AppColors.cyanAccent,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.title,
                                            style: AppTextStyles.cardTitle.copyWith(
                                              color: isSafety ? AppColors.signalAlert : Colors.white,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${n.timestamp.hour.toString().padLeft(2, '0')}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                                          style: AppTextStyles.caption.copyWith(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(n.message, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: notifications.length,
                  ),
                ),
              );
          })(),
        ],
      ),
    );
  }
}
