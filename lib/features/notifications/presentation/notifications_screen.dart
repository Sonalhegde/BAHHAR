import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfacePure,
      appBar: AppBar(
        backgroundColor: AppColors.surfacePure,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Marine Advisories & Alerts', style: AppTextStyles.subhead),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: AppColors.borderHairline, height: 1.0),
        ),
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final n = notifications[idx];
              final isSafety = n.type == 'safety';
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfacePure,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSafety ? AppColors.signalAlert.withValues(alpha: 0.3) : AppColors.borderHairline,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSafety
                            ? AppColors.signalAlert.withValues(alpha: 0.1)
                            : AppColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isSafety ? Icons.warning_amber_rounded : Icons.notifications_none_rounded,
                        size: 18,
                        color: isSafety ? AppColors.signalAlert : AppColors.accentNavy,
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
                                child: Text(n.title, style: AppTextStyles.cardTitle),
                              ),
                              Text(
                                '${n.timestamp.hour.toString().padLeft(2, '0')}:${n.timestamp.minute.toString().padLeft(2, '0')}',
                                style: AppTextStyles.caption.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(n.body, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => const Center(child: Text('No notifications available')),
      ),
    );
  }
}\n