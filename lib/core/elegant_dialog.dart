import 'package:flutter/material.dart';

/// Elegant Dialog Theme - Konsisten dengan design system Zmayy
class ElegantDialog {
  /// Show elegant dialog with custom content
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<ElegantDialogAction>? actions,
    bool dismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: const Color(0xFF181A20),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF2B2F36), width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33FCD535),
                blurRadius: 24,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Color(0x66000000),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (dismissible)
                      GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF12151B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2B2F36)),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF848E9C),
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(
                color: Color(0xFF2B2F36),
                height: 1,
                thickness: 1,
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: content,
                ),
              ),
              // Actions
              if (actions != null && actions.isNotEmpty) ...[
                const Divider(
                  color: Color(0xFF2B2F36),
                  height: 1,
                  thickness: 1,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      for (int i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: actions[i]),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Show confirmation dialog
  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Batal',
    bool isDangerous = false,
  }) {
    return show<bool>(
      context: context,
      title: title,
      content: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        ElegantDialogAction.secondary(
          text: cancelText,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        isDangerous
            ? ElegantDialogAction.danger(
                text: confirmText,
                onPressed: () => Navigator.of(context).pop(true),
              )
            : ElegantDialogAction.primary(
                text: confirmText,
                onPressed: () => Navigator.of(context).pop(true),
              ),
      ],
    );
  }

  /// Show input dialog
  static Future<String?> showInput({
    required BuildContext context,
    required String title,
    String? hint,
    String? initialValue,
    String confirmText = 'Simpan',
    String cancelText = 'Batal',
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initialValue);
    return show<String>(
      context: context,
      title: title,
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF7E8794), fontSize: 14),
          filled: true,
          fillColor: const Color(0xFF12151B),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2B2F36)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2B2F36)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFCD535), width: 1.5),
          ),
        ),
      ),
      actions: [
        ElegantDialogAction.secondary(
          text: cancelText,
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElegantDialogAction.primary(
          text: confirmText,
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
        ),
      ],
    );
  }

  /// Show loading dialog
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF181A20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2B2F36)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: Color(0xFFFCD535),
                  strokeWidth: 3,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Elegant Dialog Action Button
class ElegantDialogAction extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isOutlined;

  const ElegantDialogAction({
    super.key,
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.isOutlined = false,
  });

  factory ElegantDialogAction.primary({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElegantDialogAction(
      text: text,
      onPressed: onPressed,
      backgroundColor: const Color(0xFFFCD535),
      foregroundColor: const Color(0xFF0B0E11),
    );
  }

  factory ElegantDialogAction.secondary({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElegantDialogAction(
      text: text,
      onPressed: onPressed,
      backgroundColor: const Color(0xFF2B2F36),
      foregroundColor: Colors.white,
    );
  }

  factory ElegantDialogAction.danger({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElegantDialogAction(
      text: text,
      onPressed: onPressed,
      backgroundColor: const Color(0xFFEF4444),
      foregroundColor: Colors.white,
    );
  }

  factory ElegantDialogAction.outlined({
    required String text,
    required VoidCallback onPressed,
    Color color = const Color(0xFFFCD535),
  }) {
    return ElegantDialogAction(
      text: text,
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      foregroundColor: color,
      isOutlined: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return isOutlined
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: foregroundColor,
              side: BorderSide(color: foregroundColor, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          )
        : ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          );
  }
}
