import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Visual step-by-step application status timeline.
class StatusStepper extends StatelessWidget {
  final List<String> steps;
  final int currentStep;

  const StatusStepper({
    super.key,
    required this.steps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Step indicator column ──
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.secondary
                          : isCurrent
                              ? AppColors.primary
                              : AppColors.border,
                      border: isCurrent
                          ? Border.all(color: AppColors.primary, width: 3)
                          : null,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : isCurrent
                            ? Container(
                                margin: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: isCompleted ? AppColors.secondary : AppColors.border,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Step label ──
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                child: Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent || isCompleted ? FontWeight.w600 : FontWeight.normal,
                    color: isCompleted
                        ? AppColors.secondary
                        : isCurrent
                            ? AppColors.primary
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
