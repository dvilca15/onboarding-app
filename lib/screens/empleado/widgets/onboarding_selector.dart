import 'package:flutter/material.dart';
import '../../../models/onboarding.dart';

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
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
              color: Color(0xFF6B7280), size: 20),
          hint: const Text('Selecciona un plan'),
          items: onboardings.map((o) {
            final colorEstado = o.completado
                ? const Color(0xFF10B981)
                : o.enProgreso
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF6B7280);
            return DropdownMenuItem<int>(
              value: o.idEmployeeOnboarding,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      o.displayPlan,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF1A1A2E)),
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