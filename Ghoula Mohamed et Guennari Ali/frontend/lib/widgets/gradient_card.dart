import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class GradientCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  factory GradientCard.teal({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GradientCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      gradient: AppTheme.kPrimaryGradient,
      onTap: onTap,
    );
  }

  factory GradientCard.amber({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GradientCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      gradient: AppTheme.kAccentGradient,
      onTap: onTap,
    );
  }

  factory GradientCard.orange({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GradientCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      gradient: AppTheme.kCtaGradient,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kBlack.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.kWhite.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppTheme.kWhite, size: 22),
                ),
                if (onTap != null)
                  Icon(Icons.arrow_forward_ios,
                      color: AppTheme.kWhite.withValues(alpha: 0.7), size: 14),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.kWhite,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.kWhite.withValues(alpha: 0.9),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.kWhite.withValues(alpha: 0.7)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
