import 'package:flutter/material.dart';
import '../../../models/onboarding.dart';
import '../../../models/usuario.dart';
import '../../../models/plan.dart';
import '../widgets/stat_card.dart';
import '../widgets/onboarding_card.dart';
import '../widgets/donut_chart.dart';

class DashboardTab extends StatelessWidget {
  final List<Usuario> usuarios;
  final List<Plan> planes;
  final List<Onboarding> onboardings;

  const DashboardTab({
    super.key,
    required this.usuarios,
    required this.planes,
    required this.onboardings,
  });

  @override
  Widget build(BuildContext context) {
    final completados = onboardings.where((o) => o.completado).length;
    final enProgreso  = onboardings.where((o) => o.enProgreso).length;
    final pendientes  = onboardings.where((o) => o.estado == 'PENDIENTE').length;
    final total       = onboardings.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.8,
          children: [
            StatCard(title: 'Empleados',   value: '${usuarios.length}',  icon: Icons.people_rounded,        color: const Color(0xFF1565C0)),
            StatCard(title: 'Planes',      value: '${planes.length}',    icon: Icons.assignment_rounded,    color: const Color(0xFF7C3AED)),
            StatCard(title: 'En Progreso', value: '$enProgreso',         icon: Icons.track_changes_rounded, color: const Color(0xFFF59E0B)),
            StatCard(title: 'Completados', value: '$completados',        icon: Icons.check_circle_rounded,  color: const Color(0xFF10B981)),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Estado de onboardings',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 20),
              Row(children: [
                DonutChart(
                    completados: completados,
                    enProgreso: enProgreso,
                    pendientes: pendientes),
                const SizedBox(width: 32),
                Expanded(child: Column(children: [
                  LegendItem(label: 'Completados', value: completados,
                      total: total, color: const Color(0xFF10B981)),
                  const SizedBox(height: 12),
                  LegendItem(label: 'En progreso', value: enProgreso,
                      total: total, color: const Color(0xFFF59E0B)),
                  const SizedBox(height: 12),
                  LegendItem(label: 'Pendientes',  value: pendientes,
                      total: total, color: const Color(0xFF9CA3AF)),
                ])),
              ]),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        const Text('Onboardings recientes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...onboardings.take(5).map((o) => OnboardingCard(onboarding: o)),
      ]),
    );
  }
}