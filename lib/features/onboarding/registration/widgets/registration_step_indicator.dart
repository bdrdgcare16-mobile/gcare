// lib/features/onboarding/registration/widgets/registration_step_indicator.dart

import 'package:flutter/material.dart';

const Color _kPrimaryDark = Color(0xFF655193);

/// Horizontal step indicator for the registration wizard.
class RegistrationStepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const RegistrationStepIndicator({
    super.key,
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = i == currentStep;
        final isDone = i < currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone || isActive
                            ? _kPrimaryDark
                            : Colors.grey.shade300,
                      ),
                    ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone || isActive
                          ? _kPrimaryDark
                          : Colors.grey.shade300,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  if (i < labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isDone
                            ? _kPrimaryDark
                            : Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? _kPrimaryDark : Colors.black45,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }),
    );
  }
}
