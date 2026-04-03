import 'package:flutter/material.dart';
import '../../../models/plan.dart';
import '../../../services/api_service.dart';

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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_rounded,
                color: Color(0xFF7C3AED), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(plan.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600,
                    fontSize: 15)),
            if (plan.descripcion != null)
              Text(plan.descripcion!,
                  style: const TextStyle(fontSize: 13,
                      color: Color(0xFF6B7280))),
          ])),
          if (plan.mensajeBienvenida != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(6)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.waving_hand_rounded, size: 12,
                    color: Color(0xFF7C3AED)),
                SizedBox(width: 4),
                Text('Bienvenida',
                    style: TextStyle(color: Color(0xFF7C3AED), fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ]),
            ),
          if (plan.esPlantilla)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('Plantilla',
                  style: TextStyle(color: Color(0xFF059669), fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _btn('Agregar etapa', Icons.add, const Color(0xFF7C3AED),
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
          _btn('Ver detalle', Icons.visibility_outlined,
              const Color(0xFF6B7280), onVerDetalle),
          _btn('Editar', Icons.edit_outlined,
              const Color(0xFF1565C0), onEditar),
          _btn('Eliminar', Icons.delete_outline,
              const Color(0xFFDC2626), onEliminar),
        ]),
      ]),
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
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
}