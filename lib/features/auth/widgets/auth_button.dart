import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:workers_hub/core/theme/app_theme.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
          width: double.infinity,
          height: 56, // Fixed height for prominent button
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: Theme.of(context).elevatedButtonTheme.style!.copyWith(
              backgroundColor: MaterialStateProperty.resolveWith<Color>((
                Set<MaterialState> states,
              ) {
                if (states.contains(MaterialState.disabled)) {
                  return AppTheme.primaryColor.withOpacity(0.5);
                }
                return AppTheme.primaryColor;
              }),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.black, // Dark text color on yellow button
                      strokeWidth: 2,
                    ),
                  )
                : Text(text),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
  }
}
