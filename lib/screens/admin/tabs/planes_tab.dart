import 'package:flutter/material.dart';
import '../../../models/plan.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_widgets.dart';

class PlanesTab extends StatelessWidget {
  final List<Plan> planes;
  final void Function(Plan) onVerDetalle;
  final void Function(Plan) onEditar;
  final void Function(Plan) onEliminar;
  final void Function(int idPlan, String nombre, int cantSteps) onAgregarEtapa;

  const PlanesTab({
    super.key,
    required this.planes,
    required this.onVerDetalle,
    required this.onEditar,
    required this.onEliminar,
    required this.onAgregarEtapa,
  });

  @override
  Widget build(BuildContext context) {
    if (planes.isEmpty) {
      return const EmptyState(
        icon: Icons.assignment_outlined,
        title: 'Aún no hay planes',
        message: 'Crea tu primer plan con el botón Nuevo plan o pídele '
            'una propuesta al asistente de IA.',
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: planes.map((p) => _PlanCard(
          plan: p,
          onVerDetalle: () => onVerDetalle(p),
          onEditar: () => onEditar(p),
          onEliminar: () => onEliminar(p),
          onAgregarEtapa: onAgregarEtapa,
        )).toList(),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Plan plan;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final void Function(int idPlan, String nombre, int cantSteps) onAgregarEtapa;

  const _PlanCard({
    required this.plan,
    required this.onVerDetalle,
    required this.onEditar,
    required this.onEliminar,
    required this.onAgregarEtapa,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: const Icon(Icons.route_rounded,
                  color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(plan.nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.text)),
              if (plan.descripcion != null && plan.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(plan.descripcion!,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textMuted)),
              ],
            ])),
            const SizedBox(width: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              if (plan.mensajeBienvenida != null)
                const StatusBadge('Bienvenida',
                    tone: BadgeTone.primary, dot: false),
              if (plan.esPlantilla)
                const StatusBadge('Plantilla',
                    tone: BadgeTone.success, dot: false),
            ]),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _btn('Ver detalle', Icons.visibility_outlined,
                AppColors.textBody, onVerDetalle),
            _btn('Agregar etapa', Icons.add_rounded, AppColors.primary,
                () async {
              try {
                final detalle = await ApiService.obtenerPlan(plan.idPlan);
                final pd = PlanDetalle.fromJson(detalle);
                final cant = pd.steps
                    .where((s) => s.titulo != '__BIENVENIDA__')
                    .length;
                onAgregarEtapa(plan.idPlan, plan.nombre, cant);
              } catch (_) {
                onAgregarEtapa(plan.idPlan, plan.nombre, 0);
              }
            }),
            _btn('Editar', Icons.edit_outlined,
                AppColors.textBody, onEditar),
            _btn('Eliminar', Icons.delete_outline_rounded,
                AppColors.danger, onEliminar),
          ]),
        ]),
      ),
    );
  }

  Widget _btn(String label, IconData icon, Color color,
      VoidCallback onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
              color: color == AppColors.danger
                  ? AppColors.dangerBorder
                  : AppColors.borderStrong),
          minimumSize: const Size(0, 36),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
}
