import 'package:flutter/material.dart';
import '../../../models/onboarding.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_widgets.dart';

class OnboardingCard extends StatelessWidget {
  final Onboarding onboarding;

  const OnboardingCard({super.key, required this.onboarding});

  @override
  Widget build(BuildContext context) {
    final color = onboarding.completado
        ? AppColors.success
        : onboarding.enProgreso
            ? AppColors.primary
            : AppColors.textSubtle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            InitialAvatar(onboarding.displayEmpleado, size: 42),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(onboarding.displayEmpleado,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.text)),
                    ),
                    const SizedBox(width: 10),
                    StatusBadge.estado(onboarding.estado),
                  ]),
                  const SizedBox(height: 3),
                  Text(
                    onboarding.fechaInicio != null
                        ? '${onboarding.displayPlan} · Inicio ${onboarding.fechaInicio!.toLocal().toString().split(' ')[0]}'
                        : onboarding.displayPlan,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: AppProgressBar(
                          value: onboarding.progreso / 100, color: color),
                    ),
                    const SizedBox(width: 12),
                    Text('${onboarding.progreso.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textBody)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
