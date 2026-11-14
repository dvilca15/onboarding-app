import 'package:flutter/material.dart';
import '../../../models/onboarding.dart';
import '../../../theme/app_theme.dart';

class OnboardingSelector extends StatelessWidget {
  final List<Onboarding> onboardings;
  final int? seleccionado;
  final ValueChanged<int?> onChanged;

  const OnboardingSelector({
    super.key,
    required this.onboardings,
    required this.seleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: seleccionado,
          isExpanded: true,
          icon: const Icon(Icons.expand_more_rounded,
              color: AppColors.textMuted, size: 20),
          hint: const Text('Selecciona un plan'),
          items: onboardings.map((o) {
            final colorEstado = o.completado
                ? AppColors.success
                : o.enProgreso
                    ? AppColors.primary
                    : AppColors.textMuted;
            return DropdownMenuItem<int>(
              value: o.idEmployeeOnboarding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      o.displayPlan,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorEstado.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      o.estado,
                      style: TextStyle(
                          fontSize: 11,
                          color: colorEstado,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}