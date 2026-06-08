import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

class AppDialogs {
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    IconData icon = Icons.help_outline,
    Color accentColor = AppTheme.kPrimaryTeal,
  }) {
    return _showBlurDialog<bool?>(
      context: context,
      builder: (ctx) => _DialogContent(
        icon: Icon(icon, color: accentColor, size: 28),
        iconBg: accentColor.withValues(alpha: 0.1),
        title: title,
        message: message,
        actions: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: AppTheme.kBorderLight),
                ),
                child: Text(cancelLabel,
                    style: TextStyle(
                        color: AppTheme.kTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: AppTheme.kSurfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(confirmLabel,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool?> showDelete({
    required BuildContext context,
    required String title,
    required String itemName,
  }) {
    return _showBlurDialog<bool?>(
      context: context,
      builder: (ctx) => _DialogContent(
        icon: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.kErrorRed, size: 28),
        iconBg: AppTheme.kErrorRedLight,
        title: title,
        message: itemName,
        submessage: 'Cette action est irréversible.',
        actions: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: AppTheme.kBorderLight),
                ),
                child: const Text('Annuler',
                    style: TextStyle(
                        color: AppTheme.kTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kErrorRed,
                  foregroundColor: AppTheme.kSurfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('Supprimer',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    required String label,
    String? initialValue,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
  }) {
    final controller = TextEditingController(text: initialValue);
    return _showBlurDialog<String?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInnerState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: _DialogContent(
            icon: const Icon(Icons.edit_outlined,
                color: AppTheme.kPrimaryTeal, size: 28),
            iconBg: AppTheme.kPrimaryTealLight,
            title: title,
            actions: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: controller,
                  obscureText: isPassword,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    labelText: label,
                    hintText: hintText,
                    filled: true,
                    fillColor: AppTheme.kInputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    labelStyle: TextStyle(color: AppTheme.kTextSecondary),
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.kPrimaryTeal,
                    foregroundColor: AppTheme.kSurfaceWhite,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text('Valider',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String message,
    String title = 'Opération réussie',
  }) {
    return _showBlurDialog<void>(
      context: context,
      builder: (ctx) => _DialogContent(
        icon: const Icon(Icons.check_circle_rounded,
            color: AppTheme.kSuccessGreen, size: 28),
        iconBg: AppTheme.kSuccessGreenLight,
        title: title,
        message: message,
        actions: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kPrimaryTeal,
              foregroundColor: AppTheme.kSurfaceWhite,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Fermer',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String message,
    String title = 'Erreur',
  }) {
    return _showBlurDialog<void>(
      context: context,
      builder: (ctx) => _DialogContent(
        icon: const Icon(Icons.error_outline_rounded,
            color: AppTheme.kErrorRed, size: 28),
        iconBg: AppTheme.kErrorRedLight,
        title: title,
        message: message,
        actions: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kErrorRed,
              foregroundColor: AppTheme.kSurfaceWhite,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Fermer',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }

  static Future<T?> showActionSheet<T>({
    required BuildContext context,
    required String title,
    required List<ActionSheetItem<T>> items,
  }) {
    return _showBlurDialog<T?>(
      context: context,
      builder: (ctx) => _DialogContent(
        icon: const Icon(Icons.more_horiz_rounded,
            color: AppTheme.kPrimaryTeal, size: 28),
        iconBg: AppTheme.kPrimaryTealLight,
        title: title,
        actions: Column(
          children: items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.pop(ctx, item.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon,
                              color: item.color, size: 20),
                          const SizedBox(width: 10),
                          Text(item.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: item.color,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              )).toList(),
        ),
      ),
    );
  }

  static Future<T?> _showBlurDialog<T>({
    required BuildContext context,
    required Widget Function(BuildContext) builder,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppTheme.kBlack.withValues(alpha: 0.3),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: AppTheme.kSurfaceWhite,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kBlack.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: builder(ctx),
          ),
        ),
      ),
    );
  }
}

class _DialogContent extends StatelessWidget {
  final Widget icon;
  final Color iconBg;
  final String title;
  final String? message;
  final String? submessage;
  final Widget? actions;

  const _DialogContent({
    required this.icon,
    required this.iconBg,
    required this.title,
    this.message,
    this.submessage,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: icon,
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: AppTheme.titleMedium
                  .copyWith(fontWeight: FontWeight.bold)),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message!,
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium
                    .copyWith(color: AppTheme.kTextSecondary)),
          ],
          if (submessage != null) ...[
            const SizedBox(height: 4),
            Text(submessage!,
                textAlign: TextAlign.center,
                style: AppTheme.bodySmall
                    .copyWith(color: AppTheme.kTextSecondary)),
          ],
          if (actions != null) ...[
            const SizedBox(height: 18),
            actions!,
          ],
        ],
      ),
    );
  }
}

class ActionSheetItem<T> {
  final T value;
  final String label;
  final IconData icon;
  final Color color;

  const ActionSheetItem({
    required this.value,
    required this.label,
    required this.icon,
    this.color = AppTheme.kPrimaryTeal,
  });
}
