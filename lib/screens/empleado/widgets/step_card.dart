import 'package:flutter/material.dart';
import '../../../models/onboarding.dart';
import 'task_row.dart';

class StepCard extends StatelessWidget {
  final StepConProgreso step;
  final int numero;
  final bool expandido;
  final VoidCallback onToggle;
  final Future<void> Function(int idTask) onCompletarTask;

  const StepCard({
    super.key,
    required this.step,
    required this.numero,
    required this.expandido,
    required this.onToggle,
    required this.onCompletarTask,
  });

  @override
  Widget build(BuildContext context) {
    final colorStep = step.todoCompleto
        ? const Color(0xFF10B981)
        : step.enProgreso
            ? const Color(0xFFF59E0B)
            : const Color(0xFF9CA3AF);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: step.todoCompleto
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Cabecera ──────────────────────────────────────
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Número / check
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: step.todoCompleto
                          ? const Color(0xFF10B981)
                          : colorStep.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: step.todoCompleto
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : Text(
                              '$numero',
                              style: TextStyle(
                                color: colorStep,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título + subtítulo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.titulo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: step.todoCompleto
                                ? const Color(0xFF6B7280)
                                : const Color(0xFF1A1A2E),
                            decoration: step.todoCompleto
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${step.completadas}/${step.totalTasks} tareas',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorStep,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (step.duracionDias != null) ...[
                              const Text(' · ',
                                  style: TextStyle(
                                      color: Color(0xFF9CA3AF), fontSize: 12)),
                              Text('${step.duracionDias} días',
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF9CA3AF))),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Porcentaje + chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${step.porcentaje}%',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorStep),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        expandido
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Barra de progreso ─────────────────────────────
          if (step.totalTasks > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: step.totalTasks > 0
                      ? step.completadas / step.totalTasks
                      : 0,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation<Color>(colorStep),
                  minHeight: 4,
                ),
              ),
            ),

          // ── Descripción ───────────────────────────────────
          if (expandido &&
              step.descripcion != null &&
              step.descripcion!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(step.descripcion!,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280))),
              ),
            ),

          // ── Lista de tasks ────────────────────────────────
          if (expandido && step.tasks.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Divider(height: 1, color: Color(0xFFF3F4F6)),
            ),
            ...step.tasks.map((t) => TaskRow(
                  task: t,
                  onCompletar: () => onCompletarTask(t.idTask),
                )),
          ],

          if (expandido && step.tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Esta etapa no tiene tareas.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
            ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}