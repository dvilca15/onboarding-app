import 'package:flutter/material.dart';
import '../../../models/onboarding.dart';

class OnboardingCard extends StatelessWidget {
  final Onboarding onboarding;

  const OnboardingCard({super.key, required this.onboarding});

  @override
  Widget build(BuildContext context) {
    final color = onboarding.completado
        ? const Color(0xFF10B981)
        : onboarding.enProgreso
            ? const Color(0xFFF59E0B)
            : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  onboarding.displayEmpleado,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  onboarding.displayPlan,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                if (onboarding.fechaInicio != null)
                  Text(
                    'Inicio: ${onboarding.fechaInicio!.toLocal().toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: onboarding.progreso / 100,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  '${onboarding.progreso.toStringAsFixed(0)}% completado',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              onboarding.estado,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}