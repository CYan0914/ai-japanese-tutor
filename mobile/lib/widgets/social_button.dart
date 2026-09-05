/// Social sign-in button (Apple, Google, etc.) — branded background
/// with optional border, busy-state spinner, and 52px height so Apple
/// sign-in sits above Google's, both above email.
import 'package:flutter/material.dart';
import '../config/tokens.dart';

class SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final bool busy;
  final VoidCallback onTap;

  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.border,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(SakuraRadius.m),
          side: border != null
              ? BorderSide(color: border!)
              : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(SakuraRadius.m),
          onTap: busy ? null : onTap,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: foreground, size: 22),
                      const SizedBox(width: SakuraSpace.s),
                      Text(
                        label,
                        style: SakuraType.label(
                            color: foreground, size: 15),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
