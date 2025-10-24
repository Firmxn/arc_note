import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const AuthButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isOutlined = false,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  const AuthButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  }) : isOutlined = true;

  @override
  Widget build(BuildContext context) {
    final buttonColor = backgroundColor ?? Theme.of(context).colorScheme.primary;
    final textColor = foregroundColor ?? (isOutlined
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onPrimary);
    final border = borderColor ?? Theme.of(context).colorScheme.primary;

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: child,
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: child,
      );
    }
  }
}