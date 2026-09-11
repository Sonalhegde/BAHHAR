import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/glass_tokens.dart';

class GlassModal {
  static Future<T?> showBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(GlassTokens.radiusLarge)),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassTokens.blurProminent,
              sigmaY: GlassTokens.blurProminent,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              decoration: BoxDecoration(
                color: const Color(0xFF07192C).withValues(alpha: 0.88),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(GlassTokens.radiusLarge)),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.2),
                  left: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                  right: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle indicator
                  Container(
                    width: 38,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
