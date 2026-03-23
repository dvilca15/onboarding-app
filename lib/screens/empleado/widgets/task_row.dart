import 'package:flutter/material.dart';
import '../../../models/onboarding.dart';

class TaskRow extends StatelessWidget {
  final TaskProgressDetalle task;
  final VoidCallback onCompletar;

  const TaskRow({
    super.key,
    required this.task,
    required this.onCompletar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Row(
        children: [
          // Checkbox animado
          GestureDetector(
            onTap: task.completada ? null : onCompletar,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: task.completada
                    ? const Color(0xFF10B981)
                    : Colors.transparent,
                border: Border.all(
                  color: task.completada
                      ? const Color(0xFF10B981)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.completada
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 10),

          // Título + badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.titulo,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: task.completada
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF1A1A2E),
                    decoration:
                        task.completada ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    _TipoBadge(tipo: task.tipo),
                    if (task.obligatorio) ...[
                      const SizedBox(width: 6),
                      const Text(
                        'Obligatoria',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Botón completar
          if (!task.completada)
            TextButton(
              onPressed: onCompletar,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              child: const Text('Completar', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _TipoBadge extends StatelessWidget {
  final String tipo;
  const _TipoBadge({required this.tipo});

  static const _colors = {
    'DOCUMENTO':    [Color(0xFFEFF6FF), Color(0xFF3B82F6)],
    'VIDEO':        [Color(0xFFFFF7ED), Color(0xFFF97316)],
    'FORMULARIO':   [Color(0xFFF5F3FF), Color(0xFF8B5CF6)],
    'CONFIRMACION': [Color(0xFFF0FDF4), Color(0xFF22C55E)],
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors[tipo] ??
        [const Color(0xFFF3F4F6), const Color(0xFF6B7280)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c[0],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tipo,
        style: TextStyle(
            fontSize: 10, color: c[1], fontWeight: FontWeight.w500),
      ),
    );
  }
}