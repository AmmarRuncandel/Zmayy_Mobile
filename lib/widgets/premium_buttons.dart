import 'package:flutter/material.dart';

import '../core/zmayy_colors.dart';

class PrimaryGoldFilledButton extends StatelessWidget {
  const PrimaryGoldFilledButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;

    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: ButtonStyle(
        backgroundColor:
            WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) => ZmayyColors.gold),
        foregroundColor:
            WidgetStateProperty.resolveWith<Color>((_) => ZmayyColors.base),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        padding:
            WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
        elevation: WidgetStateProperty.resolveWith((Set<WidgetState> s) =>
            s.contains(WidgetState.disabled) ? 0 : 2),
      ),
      child: busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: ZmayyColors.base)) : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class OutlineMutedButton extends StatelessWidget {
  const OutlineMutedButton({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0x0DFFFFFF),
        foregroundColor: ZmayyColors.primaryText,
        side: const BorderSide(color: ZmayyColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class DangerElevatedChip extends StatelessWidget {
  const DangerElevatedChip({super.key, required this.label, this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !busy;

    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: ZmayyColors.danger,
        foregroundColor: Colors.white,
        elevation: enabled ? 2 : 0,
        disabledBackgroundColor: ZmayyColors.danger.withAlpha(90),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
