import 'package:flutter/material.dart';
import '../../../models/onboarding.dart';
import '../../../models/usuario.dart';
import '../../../models/plan.dart';
import '../widgets/stat_card.dart';
import '../widgets/onboarding_card.dart';
import '../widgets/donut_chart.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_widgets.dart';

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
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        LayoutBuilder(builder: (context, c) {
          final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 520 ? 2 : 1);
          return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16, mainAxisSpacing: 16,
          mainAxisExtent: 104,
          children: [
            StatCard(title: 'Empleados',   value: '${usuarios.length}',  icon: Icons.people_rounded,        color: AppColors.primary),
            StatCard(title: 'Planes',      value: '${planes.length}',    icon: Icons.assignment_rounded,    color: AppColors.primary),
            StatCard(title: 'En Progreso', value: '$enProgreso',         icon: Icons.track_changes_rounded, color: AppColors.warning),
            StatCard(title: 'Completados', value: '$completados',        icon: Icons.check_circle_rounded,  color: AppColors.success),
          ],
        );
        }),
        if (total > 0) ...[
          const SizedBox(height: 24),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Estado de onboardings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                      color: AppColors.text)),
              const SizedBox(height: 20),
              Row(children: [
                DonutChart(
                    completados: completados,
                    enProgreso: enProgreso,
                    pendientes: pendientes),
                const SizedBox(width: 32),
                Expanded(child: Column(children: [
                  LegendItem(label: 'Completados', value: completados,
                      total: total, color: AppColors.success),
                  const SizedBox(height: 12),
                  LegendItem(label: 'En progreso', value: enProgreso,
                      total: total, color: AppColors.warning),
                  const SizedBox(height: 12),
                  LegendItem(label: 'Pendientes',  value: pendientes,
                      total: total, color: AppColors.textSubtle),
                ])),
              ]),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        const Text('Onboardings recientes',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text)),
        const SizedBox(height: 12),
        ...onboardings.take(5).map((o) => OnboardingCard(onboarding: o)),
      ]),
    );
  }
}